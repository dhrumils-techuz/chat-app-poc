import { Router } from 'express';
import { folderController } from '../controllers/folder.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { tenantMiddleware } from '../middleware/tenant.middleware';

const router = Router();

router.use(authMiddleware, tenantMiddleware);

router.post('/', (req, res, next) => folderController.create(req, res, next));
router.get('/', (req, res, next) => folderController.getAll(req, res, next));
router.put('/:id', (req, res, next) => folderController.update(req, res, next));
router.delete('/:id', (req, res, next) => folderController.delete(req, res, next));
router.post('/:id/conversations', (req, res, next) => folderController.addConversation(req, res, next));
router.delete('/:id/conversations/:conversationId', (req, res, next) => folderController.removeConversation(req, res, next));
router.get('/:id/conversations', (req, res, next) => folderController.getFolderConversations(req, res, next));

export default router;
