import { Socket, Server } from 'socket.io';
import { messageService } from '../../services/message.service';
import { SOCKET_EVENTS } from '../../types/socket-events';
import { JwtPayload } from '../../types';
import { logger } from '../../utils/logger';

export function handleReadReceiptEvents(socket: Socket, io: Server, auth: JwtPayload): void {
  const { userId, tenantId } = auth;

  socket.on(SOCKET_EVENTS.MESSAGE_DELIVERED, async (data) => {
    try {
      const { messageId, conversationId } = data;
      if (!messageId || !conversationId) return;

      // Mark ALL messages in this conversation up to (and including) the given
      // messageId as delivered for this user.
      await messageService.markAllMessagesUpTo({
        upToMessageId: messageId,
        userId,
        status: 'delivered',
        conversationId,
        tenantId,
      });

      const now = new Date().toISOString();

      // Broadcast to the conversation room so the sender sees the double-tick
      socket.to(`conversation:${conversationId}`).emit(SOCKET_EVENTS.MESSAGE_DELIVERED_ACK, {
        messageId,
        conversationId,
        userId,
        timestamp: now,
      });
    } catch (error) {
      logger.error('Error handling message:delivered', {
        error: error instanceof Error ? error.message : 'Unknown',
      });
    }
  });

  socket.on(SOCKET_EVENTS.MESSAGE_READ, async (data) => {
    try {
      const { messageId, conversationId } = data;
      if (!messageId || !conversationId) return;

      // Mark ALL messages in this conversation up to (and including) the given
      // messageId as read for this user.
      await messageService.markAllMessagesUpTo({
        upToMessageId: messageId,
        userId,
        status: 'read',
        conversationId,
        tenantId,
      });

      const now = new Date().toISOString();

      // Broadcast to the conversation room so the sender sees the blue double-tick
      socket.to(`conversation:${conversationId}`).emit(SOCKET_EVENTS.MESSAGE_READ_ACK, {
        messageId,
        conversationId,
        userId,
        timestamp: now,
      });
    } catch (error) {
      logger.error('Error handling message:read', {
        error: error instanceof Error ? error.message : 'Unknown',
      });
    }
  });
}
