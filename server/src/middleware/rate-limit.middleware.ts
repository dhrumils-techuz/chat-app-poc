import rateLimit from 'express-rate-limit';
import { env } from '../config/env';
import { RateLimitMsg, ErrorCode } from '../constants/messages';

export const globalRateLimit = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX_REQUESTS,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: RateLimitMsg.TOO_MANY_REQUESTS,
    code: ErrorCode.RATE_LIMIT_EXCEEDED,
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
    error: RateLimitMsg.TOO_MANY_AUTH_ATTEMPTS,
    code: ErrorCode.AUTH_RATE_LIMIT_EXCEEDED,
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
    error: RateLimitMsg.UPLOAD_LIMIT_EXCEEDED,
    code: ErrorCode.UPLOAD_RATE_LIMIT_EXCEEDED,
  },
  keyGenerator: (req) => {
    return req.auth?.userId || req.ip || 'anonymous';
  },
});
