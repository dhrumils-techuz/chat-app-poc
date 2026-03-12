import { Request, Response, NextFunction } from 'express';
import { folderService } from '../services/folder.service';
import {
  createFolderSchema,
  updateFolderSchema,
  addConversationToFolderSchema,
  uuidParamSchema,
} from '../utils/validators';

export class FolderController {
  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const input = createFolderSchema.parse(req.body);

      const folder = await folderService.createFolder(auth.tenantId, auth.userId, input);

      res.status(201).json({
        success: true,
        data: folder,
      });
    } catch (error) {
      next(error);
    }
  }

  async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const folders = await folderService.getFolders(auth.tenantId, auth.userId);

      res.status(200).json({
        success: true,
        data: folders,
      });
    } catch (error) {
      next(error);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id } = uuidParamSchema.parse(req.params);
      const input = updateFolderSchema.parse(req.body);

      const folder = await folderService.updateFolder(id, auth.tenantId, auth.userId, input);

      res.status(200).json({
        success: true,
        data: folder,
      });
    } catch (error) {
      next(error);
    }
  }

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id } = uuidParamSchema.parse(req.params);

      await folderService.deleteFolder(id, auth.tenantId, auth.userId);

      res.status(200).json({
        success: true,
        message: 'Folder deleted',
      });
    } catch (error) {
      next(error);
    }
  }

  async addConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const folderId = req.params.id;
      const input = addConversationToFolderSchema.parse(req.body);

      await folderService.addConversationToFolder(
        folderId,
        input.conversationId,
        auth.tenantId,
        auth.userId
      );

      res.status(200).json({
        success: true,
        message: 'Conversation added to folder',
      });
    } catch (error) {
      next(error);
    }
  }

  async removeConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id: folderId, conversationId } = req.params;

      await folderService.removeConversationFromFolder(
        folderId,
        conversationId,
        auth.tenantId,
        auth.userId
      );

      res.status(200).json({
        success: true,
        message: 'Conversation removed from folder',
      });
    } catch (error) {
      next(error);
    }
  }

  async getFolderConversations(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id } = uuidParamSchema.parse(req.params);

      const conversationIds = await folderService.getFolderConversations(
        id,
        auth.tenantId,
        auth.userId
      );

      res.status(200).json({
        success: true,
        data: conversationIds,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const folderController = new FolderController();
