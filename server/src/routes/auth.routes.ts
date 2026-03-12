import { Router } from 'express';
import { authController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { authRateLimit } from '../middleware/rate-limit.middleware';

const router = Router();

router.post('/login', authRateLimit, (req, res, next) => authController.login(req, res, next));
router.post('/refresh', authRateLimit, (req, res, next) => authController.refresh(req, res, next));
router.post('/logout', authMiddleware, (req, res, next) => authController.logout(req, res, next));
router.post('/change-password', authMiddleware, (req, res, next) => authController.changePassword(req, res, next));

export default router;
