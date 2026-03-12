import { Request, Response, NextFunction } from 'express';
import { conversationService } from '../services/conversation.service';
import {
  createConversationSchema,
  updateConversationSchema,
  addParticipantSchema,
  uuidParamSchema,
} from '../utils/validators';

export class ConversationController {
  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const input = createConversationSchema.parse(req.body);

      const conversation = await conversationService.createConversation(
        auth.tenantId,
        auth.userId,
        input
      );

      res.status(201).json({
        success: true,
        data: conversation,
      });
    } catch (error) {
      next(error);
    }
  }

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id } = uuidParamSchema.parse(req.params);

      const conversation = await conversationService.getConversationById(
        id,
        auth.tenantId,
        auth.userId
      );

      res.status(200).json({
        success: true,
        data: conversation,
      });
    } catch (error) {
      next(error);
    }
  }

  async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { limit = '20', offset = '0' } = req.query;

      const result = await conversationService.getUserConversations(
        auth.tenantId,
        auth.userId,
        {
          limit: Math.min(parseInt(limit as string, 10) || 20, 100),
          offset: parseInt(offset as string, 10) || 0,
        }
      );

      res.setHeader('X-Total-Count', result.total.toString());
      res.status(200).json({
        success: true,
        data: result.conversations,
        total: result.total,
      });
    } catch (error) {
      next(error);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id } = uuidParamSchema.parse(req.params);
      const input = updateConversationSchema.parse(req.body);

      const conversation = await conversationService.updateConversation(
        id,
        auth.tenantId,
        auth.userId,
        input
      );

      res.status(200).json({
        success: true,
        data: conversation,
      });
    } catch (error) {
      next(error);
    }
  }

  async addParticipant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id } = uuidParamSchema.parse(req.params);
      const input = addParticipantSchema.parse(req.body);

      await conversationService.addParticipant(
        id,
        auth.tenantId,
        auth.userId,
        input.userId,
        input.role
      );

      res.status(200).json({
        success: true,
        message: 'Participant added',
      });
    } catch (error) {
      next(error);
    }
  }

  async removeParticipant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.id;
      const participantUserId = req.params.userId;

      if (!conversationId || !participantUserId) {
        res.status(400).json({ error: 'Missing required parameters', code: 'BAD_REQUEST' });
        return;
      }

      await conversationService.removeParticipant(
        conversationId,
        auth.tenantId,
        auth.userId,
        participantUserId
      );

      res.status(200).json({
        success: true,
        message: 'Participant removed',
      });
    } catch (error) {
      next(error);
    }
  }
}

export const conversationController = new ConversationController();
