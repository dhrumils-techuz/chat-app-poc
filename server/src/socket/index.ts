import { Server } from 'socket.io';
import { verifyAccessToken } from '../utils/jwt.util';
import { handleConnection } from './handlers/connection.handler';
import { handleMessageEvents } from './handlers/message.handler';
import { handleTypingEvents } from './handlers/typing.handler';
import { handlePresenceEvents } from './handlers/presence.handler';
import { handleReadReceiptEvents } from './handlers/read-receipt.handler';
import { SOCKET_EVENTS } from '../types/socket-events';
import { logger } from '../utils/logger';
import { JwtPayload } from '../types';

export function initializeSocket(io: Server): void {
  // Authentication middleware for Socket.IO
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        next(new Error('Authentication token required'));
        return;
      }

      const payload = verifyAccessToken(token);
      (socket as any).auth = payload;
      next();
    } catch (error: any) {
      if (error.name === 'TokenExpiredError') {
        next(new Error('Token expired'));
        return;
      }
      next(new Error('Invalid authentication token'));
    }
  });

  io.on('connection', (socket) => {
    const auth: JwtPayload = (socket as any).auth;

    if (!auth || !auth.userId || !auth.tenantId) {
      socket.emit(SOCKET_EVENTS.ERROR, { message: 'Invalid authentication', code: 'AUTH_INVALID' });
      socket.disconnect(true);
      return;
    }

    // Handle connection lifecycle
    handleConnection(socket, auth);

    // Register event handlers
    handleMessageEvents(socket, io, auth);
    handleTypingEvents(socket, io, auth);
    handlePresenceEvents(socket, io, auth);
    handleReadReceiptEvents(socket, io, auth);
  });

  logger.info('Socket.IO event handlers initialized');
}
