import { Router } from 'express';
import { conversationController } from '../controllers/conversation.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { tenantMiddleware } from '../middleware/tenant.middleware';

const router = Router();

router.use(authMiddleware, tenantMiddleware);

router.post('/', (req, res, next) => conversationController.create(req, res, next));
router.get('/', (req, res, next) => conversationController.getAll(req, res, next));
router.get('/:id', (req, res, next) => conversationController.getById(req, res, next));
router.put('/:id', (req, res, next) => conversationController.update(req, res, next));
router.post('/:id/participants', (req, res, next) => conversationController.addParticipant(req, res, next));
router.delete('/:id/participants/:userId', (req, res, next) => conversationController.removeParticipant(req, res, next));

export default router;
