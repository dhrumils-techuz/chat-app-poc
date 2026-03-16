import { Router } from 'express';
import { messageController } from '../controllers/message.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { tenantMiddleware } from '../middleware/tenant.middleware';

const router = Router();

router.use(authMiddleware, tenantMiddleware);

router.post('/:conversationId/read', (req, res, next) => messageController.markAsRead(req, res, next));
router.post('/:conversationId/delivered', (req, res, next) => messageController.markAsDelivered(req, res, next));
router.post('/:conversationId', (req, res, next) => messageController.send(req, res, next));
router.get('/:conversationId', (req, res, next) => messageController.getMessages(req, res, next));
router.get('/:conversationId/:messageId', (req, res, next) => messageController.getMessage(req, res, next));
router.delete('/:conversationId/:messageId', (req, res, next) => messageController.deleteMessage(req, res, next));

export default router;
