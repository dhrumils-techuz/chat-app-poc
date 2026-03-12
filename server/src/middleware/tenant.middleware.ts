import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';

export function tenantMiddleware(req: Request, res: Response, next: NextFunction): void {
  if (!req.auth) {
    res.status(401).json({
      error: 'Authentication required',
      code: 'AUTH_REQUIRED',
    });
    return;
  }

  if (!req.auth.tenantId) {
    logger.warn('Request missing tenant context', {
      userId: req.auth.userId,
      requestId: req.auth.requestId,
    });
    res.status(403).json({
      error: 'Tenant context required',
      code: 'TENANT_MISSING',
    });
    return;
  }

  next();
}
