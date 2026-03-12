import { Socket } from 'socket.io';
import { query } from '../../config/database';
import { redis, CACHE_KEYS } from '../../config/redis';
import { SOCKET_EVENTS } from '../../types/socket-events';
import { logger } from '../../utils/logger';
import { JwtPayload } from '../../types';

export function handleConnection(socket: Socket, auth: JwtPayload): void {
  const { userId, tenantId } = auth;

  logger.info('Socket connected', { userId, socketId: socket.id });

  // Set user presence to online
  redis
    .set(CACHE_KEYS.userPresence(userId), JSON.stringify({
      status: 'online',
      socketId: socket.id,
      lastSeenAt: new Date().toISOString(),
    }))
    .catch((err) => logger.error('Failed to set presence', { error: err.message }));

  // Update last_seen_at in database
  query('UPDATE users SET last_seen_at = NOW() WHERE id = $1', [userId]).catch((err) =>
    logger.error('Failed to update last_seen_at', { error: err.message })
  );

  // Auto-join user's conversation rooms
  joinUserConversations(socket, userId, tenantId).catch((err) =>
    logger.error('Failed to join conversations', { error: err.message })
  );

  // Broadcast online status
  socket.broadcast.emit(SOCKET_EVENTS.PRESENCE_UPDATE, {
    userId,
    status: 'online',
    lastSeenAt: new Date().toISOString(),
  });

  // Handle disconnect
  socket.on('disconnect', async (reason) => {
    logger.info('Socket disconnected', { userId, socketId: socket.id, reason });

    const now = new Date().toISOString();

    await redis
      .set(CACHE_KEYS.userPresence(userId), JSON.stringify({
        status: 'offline',
        socketId: null,
        lastSeenAt: now,
      }), 'EX', 86400)
      .catch((err) => logger.error('Failed to update presence on disconnect', { error: err.message }));

    await query('UPDATE users SET last_seen_at = NOW() WHERE id = $1', [userId]).catch((err) =>
      logger.error('Failed to update last_seen_at on disconnect', { error: err.message })
    );

    socket.broadcast.emit(SOCKET_EVENTS.PRESENCE_UPDATE, {
      userId,
      status: 'offline',
      lastSeenAt: now,
    });
  });
}

async function joinUserConversations(socket: Socket, userId: string, tenantId: string): Promise<void> {
  const result = await query<{ conversation_id: string }>(
    `SELECT cp.conversation_id
     FROM conversation_participants cp
     JOIN conversations c ON c.id = cp.conversation_id
     WHERE cp.user_id = $1 AND c.tenant_id = $2 AND cp.left_at IS NULL AND c.is_active = true`,
    [userId, tenantId]
  );

  const rooms = result.rows.map((r) => `conversation:${r.conversation_id}`);
  if (rooms.length > 0) {
    await socket.join(rooms);
    logger.debug('Joined conversation rooms', { userId, roomCount: rooms.length });
  }
}
