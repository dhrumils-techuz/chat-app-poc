import Redis from 'ioredis';
import { env } from './env';
import { logger } from '../utils/logger';

export const redis = new Redis(env.REDIS_URL, {
  maxRetriesPerRequest: 3,
  retryStrategy(times: number) {
    const delay = Math.min(times * 200, 5000);
    return delay;
  },
  reconnectOnError(err: Error) {
    const targetErrors = ['READONLY', 'ECONNRESET'];
    return targetErrors.some((e) => err.message.includes(e));
  },
  lazyConnect: true,
});

redis.on('connect', () => {
  logger.info('Redis connected');
});

redis.on('error', (err) => {
  logger.error('Redis connection error', { error: err.message });
});

redis.on('close', () => {
  logger.warn('Redis connection closed');
});

export async function redisHealthCheck(): Promise<boolean> {
  try {
    const result = await redis.ping();
    return result === 'PONG';
  } catch {
    return false;
  }
}

export const CACHE_KEYS = {
  userSession: (userId: string) => `session:${userId}`,
  userPresence: (userId: string) => `presence:${userId}`,
  conversationMembers: (convId: string) => `conv:members:${convId}`,
  loginAttempts: (email: string) => `login:attempts:${email}`,
  loginLockout: (email: string) => `login:lockout:${email}`,
  typingIndicator: (convId: string, userId: string) => `typing:${convId}:${userId}`,
} as const;
