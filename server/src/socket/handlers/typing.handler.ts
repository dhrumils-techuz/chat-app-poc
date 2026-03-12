import { Socket, Server } from 'socket.io';
import { redis, CACHE_KEYS } from '../../config/redis';
import { SOCKET_EVENTS } from '../../types/socket-events';
import { JwtPayload } from '../../types';
import { query } from '../../config/database';
import { logger } from '../../utils/logger';

const TYPING_TIMEOUT_SECONDS = 5;

export function handleTypingEvents(socket: Socket, io: Server, auth: JwtPayload): void {
  const { userId } = auth;

  socket.on(SOCKET_EVENTS.TYPING_START, async (data) => {
    try {
      const { conversationId } = data;
      if (!conversationId) return;

      // Set typing indicator in Redis with TTL
      await redis.set(
        CACHE_KEYS.typingIndicator(conversationId, userId),
        '1',
        'EX',
        TYPING_TIMEOUT_SECONDS
      );

      // Get user name for display
      const userResult = await query<{ full_name: string }>(
        'SELECT full_name FROM users WHERE id = $1',
        [userId]
      );

      const userName = userResult.rows[0]?.full_name || 'Unknown';

      socket.to(`conversation:${conversationId}`).emit(SOCKET_EVENTS.TYPING_INDICATOR, {
        conversationId,
        userId,
        userName,
        isTyping: true,
      });
    } catch (error) {
      logger.error('Error handling typing:start', {
        error: error instanceof Error ? error.message : 'Unknown',
      });
    }
  });

  socket.on(SOCKET_EVENTS.TYPING_STOP, async (data) => {
    try {
      const { conversationId } = data;
      if (!conversationId) return;

      await redis.del(CACHE_KEYS.typingIndicator(conversationId, userId));

      const userResult = await query<{ full_name: string }>(
        'SELECT full_name FROM users WHERE id = $1',
        [userId]
      );

      const userName = userResult.rows[0]?.full_name || 'Unknown';

      socket.to(`conversation:${conversationId}`).emit(SOCKET_EVENTS.TYPING_INDICATOR, {
        conversationId,
        userId,
        userName,
        isTyping: false,
      });
    } catch (error) {
      logger.error('Error handling typing:stop', {
        error: error instanceof Error ? error.message : 'Unknown',
      });
    }
  });
}
