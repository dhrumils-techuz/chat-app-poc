import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import conversationRoutes from './conversation.routes';
import messageRoutes from './message.routes';
import mediaRoutes from './media.routes';
import folderRoutes from './folder.routes';
import adminRoutes from './admin.routes';
import healthRoutes from './health.routes';
import deviceRoutes from './device.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/conversations', conversationRoutes);
router.use('/messages', messageRoutes);
router.use('/media', mediaRoutes);
router.use('/folders', folderRoutes);
router.use('/devices', deviceRoutes);
router.use('/admin', adminRoutes);
router.use('/health', healthRoutes);

export default router;
