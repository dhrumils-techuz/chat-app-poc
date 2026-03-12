import { Request, Response, NextFunction } from 'express';
import { UserRole } from '../types';

const ROLE_HIERARCHY: Record<UserRole, number> = {
  super_admin: 3,
  tenant_admin: 2,
  user: 1,
};

export function requireRole(...allowedRoles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.auth) {
      res.status(401).json({
        error: 'Authentication required',
        code: 'AUTH_REQUIRED',
      });
      return;
    }

    if (!allowedRoles.includes(req.auth.role)) {
      res.status(403).json({
        error: 'Insufficient permissions',
        code: 'FORBIDDEN',
      });
      return;
    }

    next();
  };
}

export function requireMinRole(minRole: UserRole) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.auth) {
      res.status(401).json({
        error: 'Authentication required',
        code: 'AUTH_REQUIRED',
      });
      return;
    }

    const userLevel = ROLE_HIERARCHY[req.auth.role] || 0;
    const requiredLevel = ROLE_HIERARCHY[minRole] || 0;

    if (userLevel < requiredLevel) {
      res.status(403).json({
        error: 'Insufficient permissions',
        code: 'FORBIDDEN',
      });
      return;
    }

    next();
  };
}

export function requireSelfOrAdmin(userIdParam: string = 'id') {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.auth) {
      res.status(401).json({
        error: 'Authentication required',
        code: 'AUTH_REQUIRED',
      });
      return;
    }

    const targetUserId = req.params[userIdParam];
    const isSelf = req.auth.userId === targetUserId;
    const isAdmin = ROLE_HIERARCHY[req.auth.role] >= ROLE_HIERARCHY['tenant_admin'];

    if (!isSelf && !isAdmin) {
      res.status(403).json({
        error: 'Insufficient permissions',
        code: 'FORBIDDEN',
      });
      return;
    }

    next();
  };
}
