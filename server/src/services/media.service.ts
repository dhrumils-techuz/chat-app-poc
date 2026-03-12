import { query } from '../config/database';
import { S3_CONFIG } from '../config/s3';
import { generateUploadUrl, generateDownloadUrl } from '../utils/s3.util';
import { AppError } from '../middleware/error-handler.middleware';
import { conversationService } from './conversation.service';
import { auditService } from './audit.service';
import { Media } from '../types';
import { RequestUploadUrlInput, ConfirmUploadInput } from '../utils/validators';

class MediaService {
  async requestUploadUrl(
    tenantId: string,
    userId: string,
    input: RequestUploadUrlInput
  ): Promise<{
    uploadUrl: string;
    mediaId: string;
    s3Key: string;
    expiresIn: number;
  }> {
    const { conversationId, fileName, mimeType, fileSize } = input;

    // Validate mime type
    if (!S3_CONFIG.allowedMimeTypes.includes(mimeType)) {
      throw AppError.badRequest(`File type ${mimeType} is not allowed`, 'INVALID_FILE_TYPE');
    }

    // Verify participant access
    const isParticipant = await conversationService.isParticipant(conversationId, userId);
    if (!isParticipant) {
      throw AppError.forbidden('You are not a participant of this conversation');
    }

    const result = await generateUploadUrl({
      tenantId,
      conversationId,
      fileName,
      mimeType,
      fileSize,
    });

    await auditService.log({
      tenantId,
      userId,
      action: 'MEDIA_UPLOAD',
      resourceType: 'media',
      resourceId: result.mediaId,
      ipAddress: null,
      userAgent: null,
      requestId: null,
      metadata: { conversationId, mimeType, fileSize },
    });

    return result;
  }

  async confirmUpload(
    tenantId: string,
    userId: string,
    input: ConfirmUploadInput
  ): Promise<Media> {
    const { mediaId, s3Key, conversationId, fileName, mimeType, fileSize } = input;

    const result = await query<Media>(
      `INSERT INTO media (id, tenant_id, conversation_id, uploaded_by, file_name, mime_type, file_size, s3_key)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [mediaId, tenantId, conversationId, userId, fileName, mimeType, fileSize, s3Key]
    );

    return result.rows[0];
  }

  async getDownloadUrl(
    mediaId: string,
    tenantId: string,
    userId: string
  ): Promise<{ downloadUrl: string; media: Media; expiresIn: number }> {
    const mediaResult = await query<Media>(
      'SELECT * FROM media WHERE id = $1 AND tenant_id = $2',
      [mediaId, tenantId]
    );

    if (mediaResult.rows.length === 0) {
      throw AppError.notFound('Media not found');
    }

    const media = mediaResult.rows[0];

    // Verify user is participant of the conversation
    const isParticipant = await conversationService.isParticipant(media.conversation_id, userId);
    if (!isParticipant) {
      throw AppError.forbidden('You do not have access to this media');
    }

    const { downloadUrl, expiresIn } = await generateDownloadUrl(media.s3_key);

    await auditService.log({
      tenantId,
      userId,
      action: 'MEDIA_DOWNLOAD',
      resourceType: 'media',
      resourceId: mediaId,
      ipAddress: null,
      userAgent: null,
      requestId: null,
      metadata: { conversationId: media.conversation_id, mimeType: media.mime_type },
    });

    return { downloadUrl, media, expiresIn };
  }

  async getMediaByConversation(
    conversationId: string,
    tenantId: string,
    userId: string,
    params: { limit: number; offset: number; mimeType?: string }
  ): Promise<{ media: Media[]; total: number }> {
    const isParticipant = await conversationService.isParticipant(conversationId, userId);
    if (!isParticipant) {
      throw AppError.forbidden('You are not a participant of this conversation');
    }

    const conditions: string[] = ['conversation_id = $1', 'tenant_id = $2'];
    const values: any[] = [conversationId, tenantId];
    let paramIndex = 3;

    if (params.mimeType) {
      conditions.push(`mime_type LIKE $${paramIndex}`);
      values.push(`${params.mimeType}%`);
      paramIndex++;
    }

    const whereClause = conditions.join(' AND ');

    const countResult = await query<{ count: string }>(
      `SELECT COUNT(*) as count FROM media WHERE ${whereClause}`,
      values
    );

    const mediaResult = await query<Media>(
      `SELECT * FROM media WHERE ${whereClause} ORDER BY created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      [...values, params.limit, params.offset]
    );

    return {
      media: mediaResult.rows,
      total: parseInt(countResult.rows[0].count, 10),
    };
  }
}

export const mediaService = new MediaService();
