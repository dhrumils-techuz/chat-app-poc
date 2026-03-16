import { query, transaction } from '../config/database';
import { AppError } from '../middleware/error-handler.middleware';
import { ConversationMsg, UserMsg } from '../constants/messages';
import { Conversation, ConversationParticipant, ConversationType } from '../types';
import { auditService } from './audit.service';
import { CreateConversationInput, UpdateConversationInput } from '../utils/validators';

interface ConversationWithParticipants extends Conversation {
  participants: {
    userId: string;
    fullName: string;
    avatarUrl: string | null;
    role: string;
  }[];
  lastMessage?: {
    id: string;
    content: string | null;
    type: string;
    senderName: string;
    createdAt: Date;
  } | null;
  unreadCount?: number;
}

class ConversationService {
  async createConversation(
    tenantId: string,
    userId: string,
    input: CreateConversationInput
  ): Promise<ConversationWithParticipants> {
    // For direct chats, ensure no duplicate exists
    if (input.type === 'direct') {
      if (input.participantIds.length !== 1) {
        throw AppError.badRequest(ConversationMsg.DIRECT_REQUIRES_ONE);
      }

      const otherUserId = input.participantIds[0];
      if (otherUserId === userId) {
        throw AppError.badRequest(ConversationMsg.CANNOT_CHAT_SELF);
      }

      const existing = await query<{ id: string }>(
        `SELECT c.id FROM conversations c
         JOIN conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.user_id = $1 AND cp1.left_at IS NULL
         JOIN conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.user_id = $2 AND cp2.left_at IS NULL
         WHERE c.tenant_id = $3 AND c.type = 'direct' AND c.is_active = true`,
        [userId, otherUserId, tenantId]
      );

      if (existing.rows.length > 0) {
        return this.getConversationById(existing.rows[0].id, tenantId, userId);
      }
    }

    // Verify all participants belong to the same tenant
    const participantCheck = await query<{ id: string }>(
      `SELECT id FROM users WHERE id = ANY($1) AND tenant_id = $2 AND is_active = true`,
      [input.participantIds, tenantId]
    );

    if (participantCheck.rows.length !== input.participantIds.length) {
      throw AppError.badRequest(ConversationMsg.PARTICIPANTS_NOT_FOUND);
    }

    const conversationId = await transaction(async (client) => {
      // Create conversation
      const convResult = await client.query(
        `INSERT INTO conversations (tenant_id, type, name, created_by, is_active)
         VALUES ($1, $2, $3, $4, true)
         RETURNING *`,
        [tenantId, input.type, input.name || null, userId]
      );
      const conversation = convResult.rows[0] as Conversation;

      // Add creator as owner
      await client.query(
        `INSERT INTO conversation_participants (conversation_id, user_id, role)
         VALUES ($1, $2, 'owner')`,
        [conversation.id, userId]
      );

      // Add other participants
      for (const participantId of input.participantIds) {
        if (participantId !== userId) {
          await client.query(
            `INSERT INTO conversation_participants (conversation_id, user_id, role)
             VALUES ($1, $2, 'member')`,
            [conversation.id, participantId]
          );
        }
      }

      await auditService.log({
        tenantId,
        userId,
        action: 'CONVERSATION_CREATE',
        resourceType: 'conversation',
        resourceId: conversation.id,
        ipAddress: null,
        userAgent: null,
        requestId: null,
        metadata: { type: input.type, participantCount: input.participantIds.length + 1 },
      });

      return conversation.id;
    });

    // Fetch after transaction commits so the data is visible
    return this.getConversationById(conversationId, tenantId, userId);
  }

  async getConversationById(
    conversationId: string,
    tenantId: string,
    userId: string
  ): Promise<ConversationWithParticipants> {
    const convResult = await query<Conversation>(
      'SELECT * FROM conversations WHERE id = $1 AND tenant_id = $2 AND is_active = true',
      [conversationId, tenantId]
    );

    if (convResult.rows.length === 0) {
      throw AppError.notFound(ConversationMsg.NOT_FOUND);
    }

    // Verify user is a participant
    const participantCheck = await query<ConversationParticipant>(
      'SELECT * FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL',
      [conversationId, userId]
    );

    if (participantCheck.rows.length === 0) {
      throw AppError.forbidden(ConversationMsg.NOT_A_PARTICIPANT);
    }

    const conversation = convResult.rows[0];

    const participants = await query<{
      userId: string;
      fullName: string;
      avatarUrl: string | null;
      role: string;
    }>(
      `SELECT u.id as "userId", u.full_name as "fullName", u.avatar_url as "avatarUrl", cp.role
       FROM conversation_participants cp
       JOIN users u ON u.id = cp.user_id
       WHERE cp.conversation_id = $1 AND cp.left_at IS NULL`,
      [conversationId]
    );

    const lastMessage = await query<{
      id: string;
      content: string | null;
      type: string;
      senderName: string;
      createdAt: Date;
    }>(
      `SELECT m.id, m.content, m.type, u.full_name as "senderName", m.created_at as "createdAt"
       FROM messages m
       JOIN users u ON u.id = m.sender_id
       WHERE m.conversation_id = $1 AND m.is_deleted = false
       ORDER BY m.created_at DESC LIMIT 1`,
      [conversationId]
    );

    return {
      ...conversation,
      participants: participants.rows,
      lastMessage: lastMessage.rows[0] || null,
      unreadCount: participantCheck.rows[0].unread_count,
    };
  }

  async getUserConversations(
    tenantId: string,
    userId: string,
    params: { limit: number; offset: number }
  ): Promise<{ conversations: ConversationWithParticipants[]; total: number }> {
    const countResult = await query<{ count: string }>(
      `SELECT COUNT(*) as count
       FROM conversations c
       JOIN conversation_participants cp ON cp.conversation_id = c.id
       WHERE c.tenant_id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL AND c.is_active = true`,
      [tenantId, userId]
    );

    const convResult = await query<Conversation & { unread_count: number }>(
      `SELECT c.*, cp.unread_count
       FROM conversations c
       JOIN conversation_participants cp ON cp.conversation_id = c.id
       WHERE c.tenant_id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL AND c.is_active = true
       ORDER BY c.updated_at DESC
       LIMIT $3 OFFSET $4`,
      [tenantId, userId, params.limit, params.offset]
    );

    const conversations: ConversationWithParticipants[] = [];

    for (const conv of convResult.rows) {
      const participants = await query<{
        userId: string;
        fullName: string;
        avatarUrl: string | null;
        role: string;
      }>(
        `SELECT u.id as "userId", u.full_name as "fullName", u.avatar_url as "avatarUrl", cp.role
         FROM conversation_participants cp
         JOIN users u ON u.id = cp.user_id
         WHERE cp.conversation_id = $1 AND cp.left_at IS NULL`,
        [conv.id]
      );

      const lastMessage = await query<{
        id: string;
        content: string | null;
        type: string;
        senderName: string;
        createdAt: Date;
      }>(
        `SELECT m.id, m.content, m.type, u.full_name as "senderName", m.created_at as "createdAt"
         FROM messages m
         JOIN users u ON u.id = m.sender_id
         WHERE m.conversation_id = $1 AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1`,
        [conv.id]
      );

      conversations.push({
        ...conv,
        participants: participants.rows,
        lastMessage: lastMessage.rows[0] || null,
        unreadCount: conv.unread_count,
      });
    }

    return {
      conversations,
      total: parseInt(countResult.rows[0].count, 10),
    };
  }

  async updateConversation(
    conversationId: string,
    tenantId: string,
    userId: string,
    input: UpdateConversationInput
  ): Promise<ConversationWithParticipants> {
    // Check participant is admin or owner
    const participantResult = await query<ConversationParticipant>(
      `SELECT * FROM conversation_participants
       WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL AND role IN ('owner', 'admin')`,
      [conversationId, userId]
    );

    if (participantResult.rows.length === 0) {
      throw AppError.forbidden(ConversationMsg.ONLY_ADMINS_CAN_UPDATE);
    }

    const setClauses: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (input.name !== undefined) {
      setClauses.push(`name = $${paramIndex}`);
      values.push(input.name);
      paramIndex++;
    }

    if (input.avatarUrl !== undefined) {
      setClauses.push(`avatar_url = $${paramIndex}`);
      values.push(input.avatarUrl);
      paramIndex++;
    }

    if (setClauses.length === 0) {
      throw AppError.badRequest(ConversationMsg.NO_FIELDS_TO_UPDATE);
    }

    setClauses.push('updated_at = NOW()');
    values.push(conversationId, tenantId);

    await query(
      `UPDATE conversations SET ${setClauses.join(', ')} WHERE id = $${paramIndex} AND tenant_id = $${paramIndex + 1}`,
      values
    );

    await auditService.log({
      tenantId,
      userId,
      action: 'CONVERSATION_UPDATE',
      resourceType: 'conversation',
      resourceId: conversationId,
      ipAddress: null,
      userAgent: null,
      requestId: null,
      metadata: { updatedFields: Object.keys(input) },
    });

    return this.getConversationById(conversationId, tenantId, userId);
  }

  async addParticipant(
    conversationId: string,
    tenantId: string,
    addedByUserId: string,
    participantUserId: string,
    role: 'admin' | 'member' = 'member'
  ): Promise<void> {
    // Check adder is admin or owner
    const adderResult = await query<ConversationParticipant>(
      `SELECT * FROM conversation_participants
       WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL AND role IN ('owner', 'admin')`,
      [conversationId, addedByUserId]
    );

    if (adderResult.rows.length === 0) {
      throw AppError.forbidden(ConversationMsg.ONLY_ADMINS_CAN_ADD);
    }

    // Verify conversation is a group
    const convResult = await query<Conversation>(
      'SELECT * FROM conversations WHERE id = $1 AND tenant_id = $2 AND type = $3',
      [conversationId, tenantId, 'group']
    );

    if (convResult.rows.length === 0) {
      throw AppError.badRequest(ConversationMsg.ONLY_GROUP_ADD);
    }

    // Check user exists in tenant
    const userResult = await query(
      'SELECT id FROM users WHERE id = $1 AND tenant_id = $2 AND is_active = true',
      [participantUserId, tenantId]
    );

    if (userResult.rows.length === 0) {
      throw AppError.notFound(UserMsg.NOT_FOUND_IN_ORG);
    }

    // Check if already a participant
    const existingResult = await query<ConversationParticipant>(
      'SELECT * FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL',
      [conversationId, participantUserId]
    );

    if (existingResult.rows.length > 0) {
      throw AppError.conflict(ConversationMsg.ALREADY_PARTICIPANT);
    }

    await query(
      `INSERT INTO conversation_participants (conversation_id, user_id, role)
       VALUES ($1, $2, $3)`,
      [conversationId, participantUserId, role]
    );

    await auditService.log({
      tenantId,
      userId: addedByUserId,
      action: 'PARTICIPANT_ADD',
      resourceType: 'conversation',
      resourceId: conversationId,
      ipAddress: null,
      userAgent: null,
      requestId: null,
      metadata: { addedUserId: participantUserId, role },
    });
  }

  async removeParticipant(
    conversationId: string,
    tenantId: string,
    removedByUserId: string,
    participantUserId: string
  ): Promise<void> {
    // Owner can remove anyone, admins can remove members, users can leave
    const removerResult = await query<ConversationParticipant>(
      'SELECT * FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL',
      [conversationId, removedByUserId]
    );

    if (removerResult.rows.length === 0) {
      throw AppError.forbidden(ConversationMsg.NOT_A_PARTICIPANT);
    }

    const isSelf = removedByUserId === participantUserId;
    const removerRole = removerResult.rows[0].role;

    if (!isSelf && removerRole !== 'owner' && removerRole !== 'admin') {
      throw AppError.forbidden(ConversationMsg.INSUFFICIENT_REMOVE_PERMS);
    }

    await query(
      `UPDATE conversation_participants SET left_at = NOW()
       WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL`,
      [conversationId, participantUserId]
    );

    await auditService.log({
      tenantId,
      userId: removedByUserId,
      action: 'PARTICIPANT_REMOVE',
      resourceType: 'conversation',
      resourceId: conversationId,
      ipAddress: null,
      userAgent: null,
      requestId: null,
      metadata: { removedUserId: participantUserId, isSelf },
    });
  }

  async isParticipant(conversationId: string, userId: string): Promise<boolean> {
    const result = await query(
      'SELECT id FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL',
      [conversationId, userId]
    );
    return result.rows.length > 0;
  }

  async getParticipantUserIds(conversationId: string): Promise<string[]> {
    const result = await query<{ user_id: string }>(
      'SELECT user_id FROM conversation_participants WHERE conversation_id = $1 AND left_at IS NULL',
      [conversationId]
    );
    return result.rows.map((r) => r.user_id);
  }
}

export const conversationService = new ConversationService();
