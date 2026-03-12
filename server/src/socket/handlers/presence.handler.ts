import { Socket, Server } from 'socket.io';
import { redis, CACHE_KEYS } from '../../config/redis';
import { SOCKET_EVENTS } from '../../types/socket-events';
import { JwtPayload } from '../../types';
import { query } from '../../config/database';
import { logger } from '../../utils/logger';

export function handlePresenceEvents(socket: Socket, io: Server, auth: JwtPayload): void {
  const { userId } = auth;

  socket.on(SOCKET_EVENTS.PRESENCE_ONLINE, async () => {
    try {
      const now = new Date().toISOString();

      await redis.set(
        CACHE_KEYS.userPresence(userId),
        JSON.stringify({
          status: 'online',
          socketId: socket.id,
          lastSeenAt: now,
        })
      );

      await query('UPDATE users SET last_seen_at = NOW() WHERE id = $1', [userId]);

      socket.broadcast.emit(SOCKET_EVENTS.PRESENCE_UPDATE, {
        userId,
        status: 'online',
        lastSeenAt: now,
      });
    } catch (error) {
      logger.error('Error handling presence:online', {
        error: error instanceof Error ? error.message : 'Unknown',
      });
    }
  });

  socket.on(SOCKET_EVENTS.PRESENCE_OFFLINE, async () => {
    try {
      const now = new Date().toISOString();

      await redis.set(
        CACHE_KEYS.userPresence(userId),
        JSON.stringify({
          status: 'offline',
          socketId: null,
          lastSeenAt: now,
        }),
        'EX',
        86400
      );

      await query('UPDATE users SET last_seen_at = NOW() WHERE id = $1', [userId]);

      socket.broadcast.emit(SOCKET_EVENTS.PRESENCE_UPDATE, {
        userId,
        status: 'offline',
        lastSeenAt: now,
      });
    } catch (error) {
      logger.error('Error handling presence:offline', {
        error: error instanceof Error ? error.message : 'Unknown',
      });
    }
  });

  socket.on(SOCKET_EVENTS.JOIN_CONVERSATIONS, async (data) => {
    try {
      const { conversationIds } = data;
      if (!Array.isArray(conversationIds)) return;

      const rooms = conversationIds.map((id: string) => `conversation:${id}`);
      await socket.join(rooms);
    } catch (error) {
      logger.error('Error handling conversations:join', {
        error: error instanceof Error ? error.message : 'Unknown',
      });
    }
  });
}
