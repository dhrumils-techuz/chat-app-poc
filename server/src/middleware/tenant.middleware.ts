import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';
import { AuthMsg, ErrorCode } from '../constants/messages';

export function tenantMiddleware(req: Request, res: Response, next: NextFunction): void {
  if (!req.auth) {
    res.status(401).json({
      error: AuthMsg.AUTHENTICATION_REQUIRED,
      code: ErrorCode.AUTH_REQUIRED,
    });
    return;
  }

  if (!req.auth.tenantId) {
    logger.warn('Request missing tenant context', {
      userId: req.auth.userId,
      requestId: req.auth.requestId,
    });
    res.status(403).json({
      error: AuthMsg.TENANT_CONTEXT_REQUIRED,
      code: ErrorCode.TENANT_MISSING,
    });
    return;
  }

  next();
}
