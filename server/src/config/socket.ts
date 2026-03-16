import { Server as HttpServer } from 'http';
import { Server, ServerOptions } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import Redis from 'ioredis';
import { env } from './env';
import { logger } from '../utils/logger';

export function createSocketServer(httpServer: HttpServer): Server {
  const origins = env.CORS_ALLOWED_ORIGINS.split(',').map((o) => o.trim());
  const isDevelopment = env.NODE_ENV === 'development';

  const opts: Partial<ServerOptions> = {
    cors: {
      origin: (origin, callback) => {
        if (!origin) { callback(null, true); return; }
        // In development, allow any localhost origin (Flutter web uses random ports)
        if (isDevelopment && /^https?:\/\/localhost(:\d+)?$/.test(origin)) {
          callback(null, true); return;
        }
        if (origins.includes(origin)) { callback(null, true); }
        else { callback(new Error(`Origin ${origin} not allowed by CORS`)); }
      },
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingInterval: 25000,
    pingTimeout: 20000,
    transports: ['websocket', 'polling'],
    allowUpgrades: true,
    maxHttpBufferSize: 1e6,
  };

  const io = new Server(httpServer, opts);

  const pubClient = new Redis(env.REDIS_URL);
  const subClient = pubClient.duplicate();

  pubClient.on('error', (err) => {
    logger.error('Socket.IO Redis pub client error', { error: err.message });
  });

  subClient.on('error', (err) => {
    logger.error('Socket.IO Redis sub client error', { error: err.message });
  });

  io.adapter(createAdapter(pubClient, subClient));

  logger.info('Socket.IO server created with Redis adapter');

  return io;
}
