import { query } from '../config/database';
import { AppError } from '../middleware/error-handler.middleware';
import { ChatFolder, ChatFolderConversation } from '../types';
import { auditService } from './audit.service';
import { conversationService } from './conversation.service';
import { CreateFolderInput, UpdateFolderInput } from '../utils/validators';

class FolderService {
  async createFolder(
    tenantId: string,
    userId: string,
    input: CreateFolderInput
  ): Promise<ChatFolder> {
    // Get next sort order
    const orderResult = await query<{ max_order: number | null }>(
      'SELECT MAX(sort_order) as max_order FROM chat_folders WHERE tenant_id = $1 AND user_id = $2',
      [tenantId, userId]
    );
    const nextOrder = (orderResult.rows[0].max_order ?? -1) + 1;

    const result = await query<ChatFolder>(
      `INSERT INTO chat_folders (tenant_id, user_id, name, color, sort_order)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [tenantId, userId, input.name, input.color || null, nextOrder]
    );

    await auditService.log({
      tenantId,
      userId,
      action: 'FOLDER_CREATE',
      resourceType: 'folder',
      resourceId: result.rows[0].id,
      ipAddress: null,
      userAgent: null,
      requestId: null,
      metadata: { name: input.name },
    });

    return result.rows[0];
  }

  async getFolders(tenantId: string, userId: string): Promise<ChatFolder[]> {
    const result = await query<ChatFolder>(
      'SELECT * FROM chat_folders WHERE tenant_id = $1 AND user_id = $2 ORDER BY sort_order ASC',
      [tenantId, userId]
    );
    return result.rows;
  }

  async updateFolder(
    folderId: string,
    tenantId: string,
    userId: string,
    input: UpdateFolderInput
  ): Promise<ChatFolder> {
    const setClauses: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (input.name !== undefined) {
      setClauses.push(`name = $${paramIndex}`);
      values.push(input.name);
      paramIndex++;
    }

    if (input.color !== undefined) {
      setClauses.push(`color = $${paramIndex}`);
      values.push(input.color);
      paramIndex++;
    }

    if (input.sortOrder !== undefined) {
      setClauses.push(`sort_order = $${paramIndex}`);
      values.push(input.sortOrder);
      paramIndex++;
    }

    if (setClauses.length === 0) {
      throw AppError.badRequest('No fields to update');
    }

    setClauses.push('updated_at = NOW()');
    values.push(folderId, tenantId, userId);

    const result = await query<ChatFolder>(
      `UPDATE chat_folders SET ${setClauses.join(', ')}
       WHERE id = $${paramIndex} AND tenant_id = $${paramIndex + 1} AND user_id = $${paramIndex + 2}
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      throw AppError.notFound('Folder not found');
    }

    await auditService.log({
      tenantId,
      userId,
      action: 'FOLDER_UPDATE',
      resourceType: 'folder',
      resourceId: folderId,
      ipAddress: null,
      userAgent: null,
      requestId: null,
      metadata: { updatedFields: Object.keys(input) },
    });

    return result.rows[0];
  }

  async deleteFolder(folderId: string, tenantId: string, userId: string): Promise<void> {
    const result = await query(
      'DELETE FROM chat_folders WHERE id = $1 AND tenant_id = $2 AND user_id = $3',
      [folderId, tenantId, userId]
    );

    if (result.rowCount === 0) {
      throw AppError.notFound('Folder not found');
    }

    await auditService.log({
      tenantId,
      userId,
      action: 'FOLDER_DELETE',
      resourceType: 'folder',
      resourceId: folderId,
      ipAddress: null,
      userAgent: null,
      requestId: null,
    });
  }

  async addConversationToFolder(
    folderId: string,
    conversationId: string,
    tenantId: string,
    userId: string
  ): Promise<void> {
    // Verify folder ownership
    const folderResult = await query(
      'SELECT id FROM chat_folders WHERE id = $1 AND tenant_id = $2 AND user_id = $3',
      [folderId, tenantId, userId]
    );
    if (folderResult.rows.length === 0) {
      throw AppError.notFound('Folder not found');
    }

    // Verify user is participant
    const isParticipant = await conversationService.isParticipant(conversationId, userId);
    if (!isParticipant) {
      throw AppError.forbidden('You are not a participant of this conversation');
    }

    // Check for duplicate
    const existing = await query(
      'SELECT id FROM chat_folder_conversations WHERE folder_id = $1 AND conversation_id = $2',
      [folderId, conversationId]
    );
    if (existing.rows.length > 0) {
      throw AppError.conflict('Conversation already in folder');
    }

    await query(
      'INSERT INTO chat_folder_conversations (folder_id, conversation_id) VALUES ($1, $2)',
      [folderId, conversationId]
    );
  }

  async removeConversationFromFolder(
    folderId: string,
    conversationId: string,
    tenantId: string,
    userId: string
  ): Promise<void> {
    const folderResult = await query(
      'SELECT id FROM chat_folders WHERE id = $1 AND tenant_id = $2 AND user_id = $3',
      [folderId, tenantId, userId]
    );
    if (folderResult.rows.length === 0) {
      throw AppError.notFound('Folder not found');
    }

    const result = await query(
      'DELETE FROM chat_folder_conversations WHERE folder_id = $1 AND conversation_id = $2',
      [folderId, conversationId]
    );

    if (result.rowCount === 0) {
      throw AppError.notFound('Conversation not found in folder');
    }
  }

  async getFolderConversations(
    folderId: string,
    tenantId: string,
    userId: string
  ): Promise<string[]> {
    const folderResult = await query(
      'SELECT id FROM chat_folders WHERE id = $1 AND tenant_id = $2 AND user_id = $3',
      [folderId, tenantId, userId]
    );
    if (folderResult.rows.length === 0) {
      throw AppError.notFound('Folder not found');
    }

    const result = await query<{ conversation_id: string }>(
      'SELECT conversation_id FROM chat_folder_conversations WHERE folder_id = $1 ORDER BY added_at ASC',
      [folderId]
    );
    return result.rows.map((r) => r.conversation_id);
  }
}

export const folderService = new FolderService();
