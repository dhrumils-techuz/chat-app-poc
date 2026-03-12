import { Request, Response, NextFunction } from 'express';
import { messageService } from '../services/message.service';
import { sendMessageSchema, uuidParamSchema } from '../utils/validators';
import { parsePaginationParams } from '../utils/pagination.util';

export class MessageController {
  async send(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.conversationId;

      if (!conversationId) {
        res.status(400).json({ error: 'Conversation ID required', code: 'BAD_REQUEST' });
        return;
      }

      const input = sendMessageSchema.parse(req.body);

      const message = await messageService.sendMessage({
        conversationId,
        senderId: auth.userId,
        tenantId: auth.tenantId,
        type: input.type,
        content: input.content,
        mediaId: input.mediaId,
        replyToId: input.replyToId,
      });

      res.status(201).json({
        success: true,
        data: message,
      });
    } catch (error) {
      next(error);
    }
  }

  async getMessages(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.conversationId;

      if (!conversationId) {
        res.status(400).json({ error: 'Conversation ID required', code: 'BAD_REQUEST' });
        return;
      }

      const pagination = parsePaginationParams(req.query);

      const result = await messageService.getMessages(
        conversationId,
        auth.userId,
        auth.tenantId,
        pagination
      );

      res.status(200).json({
        success: true,
        data: result.data,
        nextCursor: result.nextCursor,
        prevCursor: result.prevCursor,
        hasMore: result.hasMore,
      });
    } catch (error) {
      next(error);
    }
  }

  async getMessage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { conversationId, messageId } = req.params;

      if (!conversationId || !messageId) {
        res.status(400).json({ error: 'Conversation ID and Message ID required', code: 'BAD_REQUEST' });
        return;
      }

      const message = await messageService.getMessageById(
        messageId,
        conversationId,
        auth.userId
      );

      res.status(200).json({
        success: true,
        data: message,
      });
    } catch (error) {
      next(error);
    }
  }

  async deleteMessage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { conversationId, messageId } = req.params;

      if (!conversationId || !messageId) {
        res.status(400).json({ error: 'Conversation ID and Message ID required', code: 'BAD_REQUEST' });
        return;
      }

      await messageService.deleteMessage(
        messageId,
        conversationId,
        auth.userId,
        auth.tenantId
      );

      res.status(200).json({
        success: true,
        message: 'Message deleted',
      });
    } catch (error) {
      next(error);
    }
  }
}

export const messageController = new MessageController();
