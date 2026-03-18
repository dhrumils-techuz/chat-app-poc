import { Request, Response, NextFunction } from 'express';
import { messageService } from '../services/message.service';
import { ConversationMsg, MessageMsg, ErrorCode } from '../constants/messages';
import { sendMessageSchema, uuidParamSchema } from '../utils/validators';
import { parsePaginationParams } from '../utils/pagination.util';

export class MessageController {
  async send(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.conversationId;

      if (!conversationId) {
        res.status(400).json({ error: ConversationMsg.CONVERSATION_ID_REQUIRED, code: ErrorCode.BAD_REQUEST });
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
        res.status(400).json({ error: ConversationMsg.CONVERSATION_ID_REQUIRED, code: ErrorCode.BAD_REQUEST });
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
        res.status(400).json({ error: ConversationMsg.CONVERSATION_AND_MESSAGE_ID_REQUIRED, code: ErrorCode.BAD_REQUEST });
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

  async getMessageReaders(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { conversationId, messageId } = req.params;
      if (!conversationId || !messageId) {
        res.status(400).json({ error: 'conversationId and messageId required', code: ErrorCode.BAD_REQUEST });
        return;
      }

      const readers = await messageService.getMessageReaders(messageId, conversationId);
      res.status(200).json({ success: true, data: readers });
    } catch (error) {
      next(error);
    }
  }

  async searchMessages(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.conversationId;
      const q = (req.query.q as string || '').trim();
      const limit = Math.min(parseInt(req.query.limit as string, 10) || 20, 50);

      if (!conversationId) {
        res.status(400).json({ error: ConversationMsg.CONVERSATION_ID_REQUIRED, code: ErrorCode.BAD_REQUEST });
        return;
      }
      if (!q) {
        res.status(200).json({ success: true, data: [] });
        return;
      }

      const results = await messageService.searchMessages(conversationId, auth.userId, q, limit);
      res.status(200).json({ success: true, data: results });
    } catch (error) {
      next(error);
    }
  }

  async getMessagesAround(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { conversationId, messageId } = req.params;
      const limit = Math.min(parseInt(req.query.limit as string, 10) || 50, 100);

      if (!conversationId || !messageId) {
        res.status(400).json({ error: ConversationMsg.CONVERSATION_AND_MESSAGE_ID_REQUIRED, code: ErrorCode.BAD_REQUEST });
        return;
      }

      const result = await messageService.getMessagesAround(
        conversationId, auth.userId, messageId, auth.tenantId, limit
      );
      res.status(200).json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  }

  async deleteMessage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { conversationId, messageId } = req.params;

      if (!conversationId || !messageId) {
        res.status(400).json({ error: ConversationMsg.CONVERSATION_AND_MESSAGE_ID_REQUIRED, code: ErrorCode.BAD_REQUEST });
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
        message: MessageMsg.DELETED,
      });
    } catch (error) {
      next(error);
    }
  }
  async markAsRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.conversationId;

      if (!conversationId) {
        res.status(400).json({ error: ConversationMsg.CONVERSATION_ID_REQUIRED, code: ErrorCode.BAD_REQUEST });
        return;
      }

      const { messageId } = req.body || {};

      if (messageId) {
        // Mark ALL messages up to (and including) this one as read
        await messageService.markAllMessagesUpTo({
          upToMessageId: messageId,
          userId: auth.userId,
          status: 'read',
          conversationId,
          tenantId: auth.tenantId,
        });
      }

      res.status(200).json({
        success: true,
        message: MessageMsg.MARKED_AS_READ,
      });
    } catch (error) {
      next(error);
    }
  }

  async markAsDelivered(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.conversationId;

      if (!conversationId) {
        res.status(400).json({ error: ConversationMsg.CONVERSATION_ID_REQUIRED, code: ErrorCode.BAD_REQUEST });
        return;
      }

      const { messageId } = req.body || {};

      if (messageId) {
        // Mark ALL messages up to (and including) this one as delivered
        await messageService.markAllMessagesUpTo({
          upToMessageId: messageId,
          userId: auth.userId,
          status: 'delivered',
          conversationId,
          tenantId: auth.tenantId,
        });
      }

      res.status(200).json({
        success: true,
        message: MessageMsg.MARKED_AS_DELIVERED,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const messageController = new MessageController();
