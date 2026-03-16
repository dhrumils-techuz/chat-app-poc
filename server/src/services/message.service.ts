import { query, transaction } from '../config/database';
import { AppError } from '../middleware/error-handler.middleware';
import { ConversationMsg, MessageMsg } from '../constants/messages';
import { Message, MessageStatusType } from '../types';
import { auditService } from './audit.service';
import { conversationService } from './conversation.service';
import { buildCursorQuery, buildPaginatedResult } from '../utils/pagination.util';
import { PaginatedResult } from '../types';

interface MessageWithSender extends Message {
  sender_name: string;
  sender_avatar_url: string | null;
}

class MessageService {
  async sendMessage(params: {
    conversationId: string;
    senderId: string;
    tenantId: string;
    type: string;
    content?: string;
    mediaId?: string;
    replyToId?: string;
  }): Promise<MessageWithSender> {
    const { conversationId, senderId, tenantId, type, content, mediaId, replyToId } = params;

    // Verify sender is participant
    const isParticipant = await conversationService.isParticipant(conversationId, senderId);
    if (!isParticipant) {
      throw AppError.forbidden(ConversationMsg.NOT_A_PARTICIPANT);
    }

    // Verify conversation belongs to tenant
    const convCheck = await query(
      'SELECT id FROM conversations WHERE id = $1 AND tenant_id = $2 AND is_active = true',
      [conversationId, tenantId]
    );
    if (convCheck.rows.length === 0) {
      throw AppError.notFound(ConversationMsg.NOT_FOUND);
    }

    // Verify reply target exists if provided
    if (replyToId) {
      const replyCheck = await query(
        'SELECT id FROM messages WHERE id = $1 AND conversation_id = $2',
        [replyToId, conversationId]
      );
      if (replyCheck.rows.length === 0) {
        throw AppError.notFound(MessageMsg.REPLY_NOT_FOUND);
      }
    }

    return await transaction(async (client) => {
      // Insert message
      const msgResult = await client.query(
        `INSERT INTO messages (conversation_id, sender_id, type, content, media_id, reply_to_id)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [conversationId, senderId, type, content || null, mediaId || null, replyToId || null]
      );
      const message = msgResult.rows[0] as Message;

      // Insert sent status for sender
      await client.query(
        `INSERT INTO message_status (message_id, user_id, status)
         VALUES ($1, $2, 'sent')`,
        [message.id, senderId]
      );

      // Update conversation's updated_at
      await client.query(
        'UPDATE conversations SET updated_at = NOW() WHERE id = $1',
        [conversationId]
      );

      // Increment unread count for other participants
      await client.query(
        `UPDATE conversation_participants
         SET unread_count = unread_count + 1
         WHERE conversation_id = $1 AND user_id != $2 AND left_at IS NULL`,
        [conversationId, senderId]
      );

      // Get sender info
      const senderResult = await client.query(
        'SELECT full_name, avatar_url FROM users WHERE id = $1',
        [senderId]
      );

      await auditService.log({
        tenantId,
        userId: senderId,
        action: 'MESSAGE_SEND',
        resourceType: 'message',
        resourceId: message.id,
        ipAddress: null,
        userAgent: null,
        requestId: null,
        metadata: { conversationId, type },
      });

      return {
        ...message,
        sender_name: senderResult.rows[0].full_name,
        sender_avatar_url: senderResult.rows[0].avatar_url,
      };
    });
  }

  async getMessages(
    conversationId: string,
    userId: string,
    tenantId: string,
    params: { cursor?: string; limit: number; direction: 'forward' | 'backward' }
  ): Promise<PaginatedResult<MessageWithSender>> {
    // Verify participant access
    const isParticipant = await conversationService.isParticipant(conversationId, userId);
    if (!isParticipant) {
      throw AppError.forbidden(ConversationMsg.NOT_A_PARTICIPANT);
    }

    const baseQuery = `SELECT m.*, u.full_name as sender_name, u.avatar_url as sender_avatar_url
       FROM messages m
       JOIN users u ON u.id = m.sender_id
       WHERE m.conversation_id = $1 AND m.is_deleted = false`;
    const baseParams = [conversationId];

    const { query: paginatedQuery, params: paginatedParams } = buildCursorQuery({
      baseQuery,
      baseParams,
      cursor: params.cursor,
      cursorColumn: 'm.created_at',
      direction: params.direction,
      limit: params.limit,
    });

    const result = await query<MessageWithSender>(paginatedQuery, paginatedParams);

    return buildPaginatedResult(result.rows, params.limit, 'created_at');
  }

  async getMessageById(
    messageId: string,
    conversationId: string,
    userId: string
  ): Promise<MessageWithSender> {
    const isParticipant = await conversationService.isParticipant(conversationId, userId);
    if (!isParticipant) {
      throw AppError.forbidden(ConversationMsg.NOT_A_PARTICIPANT);
    }

    const result = await query<MessageWithSender>(
      `SELECT m.*, u.full_name as sender_name, u.avatar_url as sender_avatar_url
       FROM messages m
       JOIN users u ON u.id = m.sender_id
       WHERE m.id = $1 AND m.conversation_id = $2 AND m.is_deleted = false`,
      [messageId, conversationId]
    );

    if (result.rows.length === 0) {
      throw AppError.notFound(MessageMsg.NOT_FOUND);
    }

    return result.rows[0];
  }

  async updateMessageStatus(params: {
    messageId: string;
    userId: string;
    status: MessageStatusType;
    conversationId: string;
    tenantId: string;
  }): Promise<void> {
    const { messageId, userId, status, conversationId, tenantId } = params;

    // Insert or update status
    await query(
      `INSERT INTO message_status (message_id, user_id, status)
       VALUES ($1, $2, $3)
       ON CONFLICT (message_id, user_id) DO UPDATE SET status = $3, timestamp = NOW()`,
      [messageId, userId, status]
    );

    if (status === 'read') {
      // Update last_read_message_id and reset unread count
      await query(
        `UPDATE conversation_participants
         SET last_read_message_id = $1, unread_count = 0
         WHERE conversation_id = $2 AND user_id = $3 AND left_at IS NULL`,
        [messageId, conversationId, userId]
      );

      await auditService.log({
        tenantId,
        userId,
        action: 'MESSAGE_READ',
        resourceType: 'message',
        resourceId: messageId,
        ipAddress: null,
        userAgent: null,
        requestId: null,
        metadata: { conversationId },
      });
    }
  }

  async deleteMessage(
    messageId: string,
    conversationId: string,
    userId: string,
    tenantId: string
  ): Promise<void> {
    const msgResult = await query<Message>(
      'SELECT * FROM messages WHERE id = $1 AND conversation_id = $2 AND sender_id = $3',
      [messageId, conversationId, userId]
    );

    if (msgResult.rows.length === 0) {
      throw AppError.notFound(MessageMsg.NOT_FOUND_OR_NOT_SENDER);
    }

    await query(
      'UPDATE messages SET is_deleted = true, content = NULL, updated_at = NOW() WHERE id = $1',
      [messageId]
    );
  }
}

export const messageService = new MessageService();
