import { Socket, Server } from 'socket.io';
import { messageService } from '../../services/message.service';
import { SOCKET_EVENTS } from '../../types/socket-events';
import { JwtPayload } from '../../types';
import { logger } from '../../utils/logger';
import { query } from '../../config/database';

export function handleReadReceiptEvents(socket: Socket, io: Server, auth: JwtPayload): void {
  const { userId, tenantId } = auth;

  socket.on(SOCKET_EVENTS.MESSAGE_DELIVERED, async (data) => {
    try {
      const { messageId, conversationId } = data;
      if (!messageId || !conversationId) return;

      // Mark ALL messages in this conversation up to (and including) the given
      // messageId as delivered for this user.
      await messageService.markAllMessagesUpTo({
        upToMessageId: messageId,
        userId,
        status: 'delivered',
        conversationId,
        tenantId,
      });

      const now = new Date().toISOString();

      // Broadcast to the conversation room so the sender sees the double-tick
      socket.to(`conversation:${conversationId}`).emit(SOCKET_EVENTS.MESSAGE_DELIVERED_ACK, {
        messageId,
        conversationId,
        userId,
        timestamp: now,
      });
    } catch (error) {
      logger.error('Error handling message:delivered', {
        error: error instanceof Error ? error.message : 'Unknown',
      });
    }
  });

  socket.on(SOCKET_EVENTS.MESSAGE_READ, async (data) => {
    try {
      const { messageId, conversationId } = data;
      if (!messageId || !conversationId) return;

      // Mark ALL messages in this conversation up to (and including) the given
      // messageId as read for this user.
      await messageService.markAllMessagesUpTo({
        upToMessageId: messageId,
        userId,
        status: 'read',
        conversationId,
        tenantId,
      });

      const now = new Date().toISOString();

      // Emit back to the READER's own socket so their chat list clears the
      // unread badge (always, regardless of group or direct).
      socket.emit('conversation:unread:update', {
        conversationId,
        unreadCount: 0,
      });

      // Check conversation type to decide read receipt behavior
      const convResult = await query<{ type: string }>(
        'SELECT type FROM conversations WHERE id = $1',
        [conversationId]
      );
      const isGroup = convResult.rows[0]?.type === 'group';

      if (isGroup) {
        // For group chats: only emit read:ack when ALL non-sender
        // participants have read the message. Find the latest message
        // from each sender (other than the reader) and check each.
        const senders = await query<{ sender_id: string; latest_id: string }>(
          `SELECT DISTINCT ON (m.sender_id) m.sender_id, m.id AS latest_id
           FROM messages m
           WHERE m.conversation_id = $1
             AND m.sender_id != $2
             AND m.created_at <= (SELECT created_at FROM messages WHERE id = $3)
             AND m.is_deleted = false
           ORDER BY m.sender_id, m.created_at DESC`,
          [conversationId, userId, messageId]
        );

        for (const sender of senders.rows) {
          const allRead = await messageService.haveAllParticipantsRead(
            sender.latest_id,
            conversationId
          );
          if (allRead) {
            socket.to(`conversation:${conversationId}`).emit(SOCKET_EVENTS.MESSAGE_READ_ACK, {
              messageId: sender.latest_id,
              conversationId,
              userId,
              timestamp: now,
            });
          }
        }
      } else {
        // Direct chats: emit immediately (only one other person)
        socket.to(`conversation:${conversationId}`).emit(SOCKET_EVENTS.MESSAGE_READ_ACK, {
          messageId,
          conversationId,
          userId,
          timestamp: now,
        });
      }
    } catch (error) {
      logger.error('Error handling message:read', {
        error: error instanceof Error ? error.message : 'Unknown',
      });
    }
  });
}
