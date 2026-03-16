import { Request, Response, NextFunction } from 'express';
import { mediaService } from '../services/media.service';
import { ConversationMsg, ErrorCode } from '../constants/messages';
import { requestUploadUrlSchema, confirmUploadSchema, uuidParamSchema } from '../utils/validators';

export class MediaController {
  async requestUploadUrl(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const input = requestUploadUrlSchema.parse(req.body);

      const result = await mediaService.requestUploadUrl(auth.tenantId, auth.userId, input);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async confirmUpload(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const input = confirmUploadSchema.parse(req.body);

      const media = await mediaService.confirmUpload(auth.tenantId, auth.userId, input);

      res.status(201).json({
        success: true,
        data: media,
      });
    } catch (error) {
      next(error);
    }
  }

  async getDownloadUrl(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id } = uuidParamSchema.parse(req.params);

      const result = await mediaService.getDownloadUrl(id, auth.tenantId, auth.userId);

      res.status(200).json({
        success: true,
        data: {
          downloadUrl: result.downloadUrl,
          media: result.media,
          expiresIn: result.expiresIn,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  async getConversationMedia(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.conversationId;
      const { limit = '20', offset = '0', mimeType } = req.query;

      if (!conversationId) {
        res.status(400).json({ error: ConversationMsg.CONVERSATION_ID_REQUIRED, code: ErrorCode.BAD_REQUEST });
        return;
      }

      const result = await mediaService.getMediaByConversation(
        conversationId,
        auth.tenantId,
        auth.userId,
        {
          limit: Math.min(parseInt(limit as string, 10) || 20, 100),
          offset: parseInt(offset as string, 10) || 0,
          mimeType: mimeType as string | undefined,
        }
      );

      res.setHeader('X-Total-Count', result.total.toString());
      res.status(200).json({
        success: true,
        data: result.media,
        total: result.total,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const mediaController = new MediaController();
