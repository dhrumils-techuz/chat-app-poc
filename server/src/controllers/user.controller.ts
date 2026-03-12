import { Request, Response, NextFunction } from 'express';
import { userService } from '../services/user.service';
import { createUserSchema, updateUserSchema, uuidParamSchema } from '../utils/validators';
import { UserRole } from '../types';

export class UserController {
  async createUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const input = createUserSchema.parse(req.body);

      const user = await userService.createUser(auth.tenantId, input, auth.userId);

      res.status(201).json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  async getUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id } = uuidParamSchema.parse(req.params);

      const user = await userService.getUserById(id, auth.tenantId);

      res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  async getUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { search, role, isActive, limit = '20', offset = '0' } = req.query;

      const result = await userService.getUsers(auth.tenantId, {
        search: search as string | undefined,
        role: role as UserRole | undefined,
        isActive: isActive !== undefined ? isActive === 'true' : undefined,
        limit: Math.min(parseInt(limit as string, 10) || 20, 100),
        offset: parseInt(offset as string, 10) || 0,
      });

      res.setHeader('X-Total-Count', result.total.toString());
      res.status(200).json({
        success: true,
        data: result.users,
        total: result.total,
      });
    } catch (error) {
      next(error);
    }
  }

  async updateUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id } = uuidParamSchema.parse(req.params);
      const input = updateUserSchema.parse(req.body);

      const user = await userService.updateUser(id, auth.tenantId, input, auth.userId);

      res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const user = await userService.getProfile(auth.userId, auth.tenantId);

      res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  async searchUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { q, limit = '20' } = req.query;

      if (!q || typeof q !== 'string' || q.trim().length === 0) {
        res.status(400).json({
          error: 'Search query is required',
          code: 'BAD_REQUEST',
        });
        return;
      }

      const users = await userService.searchUsers(
        auth.tenantId,
        q.trim(),
        Math.min(parseInt(limit as string, 10) || 20, 50)
      );

      res.status(200).json({
        success: true,
        data: users,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const userController = new UserController();
