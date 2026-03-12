import { Request, Response, NextFunction } from 'express';
import { auditService } from '../services/audit.service';
import { AuditAction } from '../types';

const ROUTE_AUDIT_MAP: Record<string, { action: AuditAction; resourceType: string }> = {
  'POST /api/auth/login': { action: 'LOGIN', resourceType: 'session' },
  'POST /api/auth/logout': { action: 'LOGOUT', resourceType: 'session' },
  'POST /api/auth/refresh': { action: 'TOKEN_REFRESH', resourceType: 'session' },
  'POST /api/messages': { action: 'MESSAGE_SEND', resourceType: 'message' },
  'POST /api/media/upload-url': { action: 'MEDIA_UPLOAD', resourceType: 'media' },
  'GET /api/media/:id/download-url': { action: 'MEDIA_DOWNLOAD', resourceType: 'media' },
  'POST /api/conversations': { action: 'CONVERSATION_CREATE', resourceType: 'conversation' },
  'PUT /api/conversations/:id': { action: 'CONVERSATION_UPDATE', resourceType: 'conversation' },
  'POST /api/users': { action: 'USER_CREATE', resourceType: 'user' },
  'PUT /api/users/:id': { action: 'USER_UPDATE', resourceType: 'user' },
  'POST /api/folders': { action: 'FOLDER_CREATE', resourceType: 'folder' },
  'PUT /api/folders/:id': { action: 'FOLDER_UPDATE', resourceType: 'folder' },
  'DELETE /api/folders/:id': { action: 'FOLDER_DELETE', resourceType: 'folder' },
};

function matchRoute(method: string, path: string): { action: AuditAction; resourceType: string } | null {
  const exact = ROUTE_AUDIT_MAP[`${method} ${path}`];
  if (exact) return exact;

  for (const [pattern, config] of Object.entries(ROUTE_AUDIT_MAP)) {
    const [pMethod, pPath] = pattern.split(' ');
    if (pMethod !== method) continue;

    const patternParts = pPath.split('/');
    const pathParts = path.split('/');

    if (patternParts.length !== pathParts.length) continue;

    const match = patternParts.every((part, i) =>
      part.startsWith(':') || part === pathParts[i]
    );

    if (match) return config;
  }

  return null;
}

export function auditMiddleware(req: Request, res: Response, next: NextFunction): void {
  const originalEnd = res.end;
  const startTime = Date.now();

  res.end = function (this: Response, ...args: any[]): Response {
    const matched = matchRoute(req.method, req.route?.path ? `${req.baseUrl}${req.route.path}` : req.path);

    if (matched && req.auth) {
      const resourceId = req.params?.id || req.body?.id || null;

      auditService
        .log({
          tenantId: req.auth.tenantId,
          userId: req.auth.userId,
          action: matched.action,
          resourceType: matched.resourceType,
          resourceId,
          ipAddress: req.ip || req.socket.remoteAddress || null,
          userAgent: req.headers['user-agent'] || null,
          requestId: req.auth.requestId,
          metadata: {
            method: req.method,
            path: req.path,
            statusCode: res.statusCode,
            duration: Date.now() - startTime,
          },
        })
        .catch(() => {
          // Audit log failures must not crash the request
        });
    }

    return originalEnd.apply(this, args as any);
  } as any;

  next();
}
