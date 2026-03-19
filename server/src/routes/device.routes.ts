import { Router } from 'express';
import { deviceController } from '../controllers/device.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { tenantMiddleware } from '../middleware/tenant.middleware';

const router = Router();

router.use(authMiddleware, tenantMiddleware);

router.post('/fcm-token', (req, res, next) => deviceController.saveFcmToken(req, res, next));

export default router;
