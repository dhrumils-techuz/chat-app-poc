import { Router } from 'express';
import { adminController } from '../controllers/admin.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { requireRole, requireMinRole } from '../middleware/rbac.middleware';

const router = Router();

router.use(authMiddleware);

// Super admin only
router.post('/tenants', requireRole('super_admin'), (req, res, next) => adminController.createTenant(req, res, next));
router.get('/tenants', requireRole('super_admin'), (req, res, next) => adminController.getTenants(req, res, next));
router.get('/tenants/:id', requireRole('super_admin'), (req, res, next) => adminController.getTenant(req, res, next));
router.put('/tenants/:id', requireRole('super_admin'), (req, res, next) => adminController.updateTenant(req, res, next));
router.get('/tenants/:id/stats', requireRole('super_admin'), (req, res, next) => adminController.getTenantStats(req, res, next));

// Tenant admin or super admin
router.get('/audit-logs', requireMinRole('tenant_admin'), (req, res, next) => adminController.getAuditLogs(req, res, next));
router.get('/audit-logs/:tenantId', requireRole('super_admin'), (req, res, next) => adminController.getAuditLogs(req, res, next));

export default router;
