import { Router } from 'express';
import { userController } from '../controllers/user.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { tenantMiddleware } from '../middleware/tenant.middleware';
import { requireMinRole, requireSelfOrAdmin } from '../middleware/rbac.middleware';

const router = Router();

router.use(authMiddleware, tenantMiddleware);

router.get('/me', (req, res, next) => userController.getProfile(req, res, next));
router.get('/search', (req, res, next) => userController.searchUsers(req, res, next));
router.get('/', requireMinRole('tenant_admin'), (req, res, next) => userController.getUsers(req, res, next));
router.post('/', requireMinRole('tenant_admin'), (req, res, next) => userController.createUser(req, res, next));
router.get('/:id', (req, res, next) => userController.getUser(req, res, next));
router.put('/:id', requireSelfOrAdmin(), (req, res, next) => userController.updateUser(req, res, next));

export default router;
