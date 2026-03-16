import { Request, Response, NextFunction } from 'express';
import { authService } from '../services/auth.service';
import { AuthMsg } from '../constants/messages';
import { loginSchema, refreshTokenSchema, changePasswordSchema } from '../utils/validators';

export class AuthController {
  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = loginSchema.parse(req.body);

      const result = await authService.login({
        ...input,
        ipAddress: req.ip || req.socket.remoteAddress || null,
        userAgent: req.headers['user-agent'] || null,
      });

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = refreshTokenSchema.parse(req.body);

      const tokens = await authService.refreshToken({
        refreshToken: input.refreshToken,
        ipAddress: req.ip || req.socket.remoteAddress || null,
        userAgent: req.headers['user-agent'] || null,
      });

      res.status(200).json({
        success: true,
        data: tokens,
      });
    } catch (error) {
      next(error);
    }
  }

  async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;

      await authService.logout({
        userId: auth.userId,
        deviceId: auth.deviceId,
        tenantId: auth.tenantId,
        ipAddress: req.ip || req.socket.remoteAddress || null,
        userAgent: req.headers['user-agent'] || null,
      });

      res.status(200).json({
        success: true,
        message: AuthMsg.LOGGED_OUT,
      });
    } catch (error) {
      next(error);
    }
  }

  async changePassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const input = changePasswordSchema.parse(req.body);

      await authService.changePassword({
        userId: auth.userId,
        tenantId: auth.tenantId,
        currentPassword: input.currentPassword,
        newPassword: input.newPassword,
        ipAddress: req.ip || req.socket.remoteAddress || null,
        userAgent: req.headers['user-agent'] || null,
      });

      res.status(200).json({
        success: true,
        message: AuthMsg.PASSWORD_CHANGED,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const authController = new AuthController();
