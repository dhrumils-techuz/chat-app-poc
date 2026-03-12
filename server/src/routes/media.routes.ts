import { Router } from 'express';
import { mediaController } from '../controllers/media.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { tenantMiddleware } from '../middleware/tenant.middleware';
import { uploadRateLimit } from '../middleware/rate-limit.middleware';

const router = Router();

router.use(authMiddleware, tenantMiddleware);

router.post('/upload-url', uploadRateLimit, (req, res, next) => mediaController.requestUploadUrl(req, res, next));
router.post('/confirm-upload', (req, res, next) => mediaController.confirmUpload(req, res, next));
router.get('/:id/download-url', (req, res, next) => mediaController.getDownloadUrl(req, res, next));
router.get('/conversation/:conversationId', (req, res, next) => mediaController.getConversationMedia(req, res, next));

export default router;
