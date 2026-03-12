import rateLimit from 'express-rate-limit';
import { env } from '../config/env';

export const globalRateLimit = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX_REQUESTS,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many requests, please try again later',
    code: 'RATE_LIMIT_EXCEEDED',
  },
  keyGenerator: (req) => {
    return req.auth?.userId || req.ip || 'anonymous';
  },
  skip: (req) => {
    return req.path === '/api/health';
  },
});

export const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many authentication attempts, please try again later',
    code: 'AUTH_RATE_LIMIT_EXCEEDED',
  },
  keyGenerator: (req) => {
    return req.ip || 'anonymous';
  },
});

export const uploadRateLimit = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 50,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Upload limit exceeded, please try again later',
    code: 'UPLOAD_RATE_LIMIT_EXCEEDED',
  },
  keyGenerator: (req) => {
    return req.auth?.userId || req.ip || 'anonymous';
  },
});
