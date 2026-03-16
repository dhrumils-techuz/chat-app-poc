import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken, extractTokenFromHeader } from '../utils/jwt.util';
import { logger } from '../utils/logger';
import { AuthMsg, ErrorCode, ErrorMsg } from '../constants/messages';

export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  try {
    const token = extractTokenFromHeader(req.headers.authorization);

    if (!token) {
      res.status(401).json({
        error: AuthMsg.AUTHENTICATION_REQUIRED,
        code: ErrorCode.AUTH_TOKEN_MISSING,
      });
      return;
    }

    const payload = verifyAccessToken(token);

    req.auth = {
      userId: payload.userId,
      tenantId: payload.tenantId,
      role: payload.role,
      deviceId: payload.deviceId,
      requestId: (req.headers['x-request-id'] as string) || '',
    };

    next();
  } catch (error: any) {
    if (error.name === 'TokenExpiredError') {
      res.status(401).json({
        error: AuthMsg.TOKEN_EXPIRED,
        code: ErrorCode.AUTH_TOKEN_EXPIRED,
      });
      return;
    }

    if (error.name === 'JsonWebTokenError') {
      res.status(401).json({
        error: AuthMsg.INVALID_TOKEN,
        code: ErrorCode.AUTH_TOKEN_INVALID,
      });
      return;
    }

    logger.error('Auth middleware error', { error: error.message });
    res.status(500).json({
      error: ErrorMsg.INTERNAL_SERVER_ERROR,
      code: ErrorCode.AUTH_ERROR,
    });
  }
}
