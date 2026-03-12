import { S3Client } from '@aws-sdk/client-s3';
import { env } from './env';

export const s3Client = new S3Client({
  region: env.AWS_REGION,
  credentials: {
    accessKeyId: env.AWS_ACCESS_KEY_ID,
    secretAccessKey: env.AWS_SECRET_ACCESS_KEY,
  },
});

export const S3_CONFIG = {
  bucket: env.S3_BUCKET_NAME,
  presignedUrlExpiry: env.S3_PRESIGNED_URL_EXPIRY,
  allowedMimeTypes: [
    'image/jpeg',
    'image/png',
    'image/webp',
    'audio/aac',
    'audio/m4a',
    'audio/mpeg',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  ] as string[],
  sizeLimits: {
    image: 16 * 1024 * 1024,
    audio: 25 * 1024 * 1024,
    document: 100 * 1024 * 1024,
  } as Record<string, number>,
} as const;

export function getMediaCategory(mimeType: string): 'image' | 'audio' | 'document' {
  if (mimeType.startsWith('image/')) return 'image';
  if (mimeType.startsWith('audio/')) return 'audio';
  return 'document';
}

export function getMaxFileSize(mimeType: string): number {
  const category = getMediaCategory(mimeType);
  return S3_CONFIG.sizeLimits[category];
}
