import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default('0.0.0.0'),

  DATABASE_URL: z.string().url(),
  DATABASE_POOL_MIN: z.coerce.number().default(2),
  DATABASE_POOL_MAX: z.coerce.number().default(20),

  REDIS_URL: z.string(),

  JWT_PRIVATE_KEY_BASE64: z.string().min(1),
  JWT_PUBLIC_KEY_BASE64: z.string().min(1),
  JWT_ACCESS_TOKEN_EXPIRY: z.string().default('15m'),
  JWT_REFRESH_TOKEN_EXPIRY_DAYS: z.coerce.number().default(30),

  AWS_REGION: z.string().default('us-east-1'),
  AWS_ACCESS_KEY_ID: z.string().min(1),
  AWS_SECRET_ACCESS_KEY: z.string().min(1),
  S3_BUCKET_NAME: z.string().min(1),
  S3_PRESIGNED_URL_EXPIRY: z.coerce.number().default(900),

  FIREBASE_SERVICE_ACCOUNT_BASE64: z.string().optional(),

  CORS_ALLOWED_ORIGINS: z.string().default('http://localhost:3000'),

  RATE_LIMIT_WINDOW_MS: z.coerce.number().default(900000),
  RATE_LIMIT_MAX_REQUESTS: z.coerce.number().default(100),

  AUDIT_LOG_RETENTION_DAYS: z.coerce.number().default(2555),

  ENCRYPTION_KEY: z.string().optional(),

  NGROK_URL: z.string().url().optional(),
});

function loadEnv() {
  const result = envSchema.safeParse(process.env);
  if (!result.success) {
    const formatted = result.error.format();
    const missing = Object.entries(formatted)
      .filter(([key, val]) => key !== '_errors' && val && typeof val === 'object' && '_errors' in val && (val as { _errors: string[] })._errors.length > 0)
      .map(([key, val]) => `  ${key}: ${(val as { _errors: string[] })._errors.join(', ')}`)
      .join('\n');
    console.error('Environment validation failed:\n' + missing);
    process.exit(1);
  }
  return result.data;
}

export const env = loadEnv();

export const jwtPrivateKey = Buffer.from(env.JWT_PRIVATE_KEY_BASE64, 'base64').toString('utf-8');
export const jwtPublicKey = Buffer.from(env.JWT_PUBLIC_KEY_BASE64, 'base64').toString('utf-8');
