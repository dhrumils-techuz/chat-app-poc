import { Request, Response, NextFunction } from 'express';
import { conversationService } from '../services/conversation.service';
import { ConversationMsg, ErrorCode } from '../constants/messages';
import { getIO } from '../config/socket';
import { redis, CACHE_KEYS } from '../config/redis';
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

      // Notify all OTHER participants via socket so their chat list updates.
      // Also make their sockets join the new conversation room.
      try {
        const io = getIO();
        const participants = conversation.participants || [];
        for (const participant of participants) {
          const uid = participant.userId || (participant as any).id;
          if (!uid || uid === auth.userId) continue;

          // Find this user's connected sockets
          const presenceData = await redis.get(CACHE_KEYS.userPresence(uid));
          if (!presenceData) continue;
          const parsed = JSON.parse(presenceData);
          if (!parsed.socketId) continue;

          const targetSocket = io.sockets.sockets.get(parsed.socketId);
          if (targetSocket) {
            // Join the new conversation room
            targetSocket.join(`conversation:${conversation.id}`);
            // Emit the new conversation data
            targetSocket.emit('conversation:new', conversation);
          }
        }
      } catch (socketErr) {
        // Non-critical — the conversation was created successfully
      }
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
        message: ConversationMsg.PARTICIPANT_ADDED,
      });
    } catch (error) {
      next(error);
    }
  }

  async deleteConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.id;

      if (!conversationId) {
        res.status(400).json({ error: ConversationMsg.MISSING_REQUIRED_PARAMS, code: ErrorCode.BAD_REQUEST });
        return;
      }

      await conversationService.deleteConversation(conversationId, auth.tenantId, auth.userId);

      res.status(200).json({
        success: true,
        message: ConversationMsg.DELETED,
      });
    } catch (error) {
      next(error);
    }
  }

  async muteConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.id;
      const { mute } = req.body;

      if (!conversationId || mute === undefined) {
        res.status(400).json({ error: ConversationMsg.MISSING_REQUIRED_PARAMS, code: ErrorCode.BAD_REQUEST });
        return;
      }

      await conversationService.updateParticipantSetting(
        conversationId, auth.tenantId, auth.userId, 'is_muted', mute
      );

      res.status(200).json({
        success: true,
        message: mute ? ConversationMsg.MUTED : ConversationMsg.UNMUTED,
      });
    } catch (error) {
      next(error);
    }
  }

  async pinConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.id;
      const { pin } = req.body;

      if (!conversationId || pin === undefined) {
        res.status(400).json({ error: ConversationMsg.MISSING_REQUIRED_PARAMS, code: ErrorCode.BAD_REQUEST });
        return;
      }

      await conversationService.updateParticipantSetting(
        conversationId, auth.tenantId, auth.userId, 'is_pinned', pin
      );

      res.status(200).json({
        success: true,
        message: pin ? ConversationMsg.PINNED : ConversationMsg.UNPINNED,
      });
    } catch (error) {
      next(error);
    }
  }

  async archiveConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const conversationId = req.params.id;
      const { archive } = req.body;

      if (!conversationId || archive === undefined) {
        res.status(400).json({ error: ConversationMsg.MISSING_REQUIRED_PARAMS, code: ErrorCode.BAD_REQUEST });
        return;
      }

      await conversationService.updateParticipantSetting(
        conversationId, auth.tenantId, auth.userId, 'is_archived', archive
      );

      res.status(200).json({
        success: true,
        message: archive ? ConversationMsg.ARCHIVED : ConversationMsg.UNARCHIVED,
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
        res.status(400).json({ error: ConversationMsg.MISSING_REQUIRED_PARAMS, code: ErrorCode.BAD_REQUEST });
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
        message: ConversationMsg.PARTICIPANT_REMOVED,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const conversationController = new ConversationController();
