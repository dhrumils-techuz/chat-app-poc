import { Request, Response, NextFunction } from 'express';
import { adminService } from '../services/admin.service';
import { auditService } from '../services/audit.service';
import { createTenantSchema, uuidParamSchema } from '../utils/validators';
import { AuditAction } from '../types';

export class AdminController {
  async createTenant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const input = createTenantSchema.parse(req.body);

      const result = await adminService.createTenant(input, auth.userId);

      res.status(201).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async getTenants(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { limit = '20', offset = '0' } = req.query;

      const result = await adminService.getTenants({
        limit: Math.min(parseInt(limit as string, 10) || 20, 100),
        offset: parseInt(offset as string, 10) || 0,
      });

      res.setHeader('X-Total-Count', result.total.toString());
      res.status(200).json({
        success: true,
        data: result.tenants,
        total: result.total,
      });
    } catch (error) {
      next(error);
    }
  }

  async getTenant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = uuidParamSchema.parse(req.params);
      const tenant = await adminService.getTenantById(id);

      res.status(200).json({
        success: true,
        data: tenant,
      });
    } catch (error) {
      next(error);
    }
  }

  async updateTenant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { id } = uuidParamSchema.parse(req.params);

      const tenant = await adminService.updateTenant(id, req.body, auth.userId);

      res.status(200).json({
        success: true,
        data: tenant,
      });
    } catch (error) {
      next(error);
    }
  }

  async getTenantStats(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = uuidParamSchema.parse(req.params);
      const stats = await adminService.getTenantStats(id);

      res.status(200).json({
        success: true,
        data: stats,
      });
    } catch (error) {
      next(error);
    }
  }

  async getAuditLogs(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const tenantId = req.params.tenantId || auth.tenantId;
      const {
        userId,
        action,
        resourceType,
        startDate,
        endDate,
        limit = '50',
        offset = '0',
      } = req.query;

      const result = await auditService.getAuditLogs({
        tenantId,
        userId: userId as string | undefined,
        action: action as AuditAction | undefined,
        resourceType: resourceType as string | undefined,
        startDate: startDate ? new Date(startDate as string) : undefined,
        endDate: endDate ? new Date(endDate as string) : undefined,
        limit: Math.min(parseInt(limit as string, 10) || 50, 200),
        offset: parseInt(offset as string, 10) || 0,
      });

      res.setHeader('X-Total-Count', result.total.toString());
      res.status(200).json({
        success: true,
        data: result.logs,
        total: result.total,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const adminController = new AdminController();
