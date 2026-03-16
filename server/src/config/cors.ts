import { CorsOptions } from 'cors';
import { env } from './env';

const allowedOrigins = env.CORS_ALLOWED_ORIGINS.split(',').map((o) => o.trim());
const isDevelopment = env.NODE_ENV === 'development';

export const corsOptions: CorsOptions = {
  origin: (origin, callback) => {
    // No origin = same-origin or non-browser request (e.g. mobile app, Postman)
    if (!origin) {
      callback(null, true);
      return;
    }

    // In development, allow any localhost origin (Flutter web uses random ports)
    if (isDevelopment && /^https?:\/\/localhost(:\d+)?$/.test(origin)) {
      callback(null, true);
      return;
    }

    // Check against explicit allow-list
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error(`Origin ${origin} not allowed by CORS`));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID', 'X-Tenant-ID', 'X-Device-Id'],
  exposedHeaders: ['X-Request-ID', 'X-Total-Count'],
  credentials: true,
  maxAge: 86400,
};
