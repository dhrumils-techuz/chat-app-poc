import http from 'http';
import app from './app';
import { env } from './config/env';
import { redis } from './config/redis';
import { pool } from './config/database';
import { createSocketServer } from './config/socket';
import { initializeSocket } from './socket';
import { initializeFirebase } from './config/firebase';
import { logger } from './utils/logger';

async function bootstrap(): Promise<void> {
  // Connect to Redis
  await redis.connect();
  logger.info('Redis connected');

  // Verify PostgreSQL connection
  const client = await pool.connect();
  client.release();
  logger.info('PostgreSQL connected');

  // Initialize Firebase (optional)
  initializeFirebase();

  // Create HTTP server
  const server = http.createServer(app);

  // Create and initialize Socket.IO
  const io = createSocketServer(server);
  initializeSocket(io);

  // Start listening
  server.listen(env.PORT, env.HOST, () => {
    logger.info(`Server running on ${env.HOST}:${env.PORT}`, {
      env: env.NODE_ENV,
      port: env.PORT,
    });
  });

  // Graceful shutdown
  const shutdown = async (signal: string) => {
    logger.info(`${signal} received, starting graceful shutdown`);

    server.close(() => {
      logger.info('HTTP server closed');
    });

    io.close(() => {
      logger.info('Socket.IO server closed');
    });

    try {
      await redis.quit();
      logger.info('Redis connection closed');
    } catch {
      logger.warn('Redis connection close failed');
    }

    try {
      await pool.end();
      logger.info('PostgreSQL pool closed');
    } catch {
      logger.warn('PostgreSQL pool close failed');
    }

    process.exit(0);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));

  process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection', {
      reason: reason instanceof Error ? reason.message : String(reason),
    });
  });

  process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception', {
      error: error.message,
      stack: error.stack,
    });
    process.exit(1);
  });
}

bootstrap().catch((error) => {
  logger.error('Failed to start server', {
    error: error.message,
    stack: error.stack,
  });
  process.exit(1);
});
