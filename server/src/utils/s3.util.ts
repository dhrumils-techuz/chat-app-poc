import { PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';
import { s3Client, S3_CONFIG, getMaxFileSize } from '../config/s3';

export interface PresignedUploadResult {
  uploadUrl: string;
  s3Key: string;
  mediaId: string;
  expiresIn: number;
}

export interface PresignedDownloadResult {
  downloadUrl: string;
  expiresIn: number;
}

export async function generateUploadUrl(params: {
  tenantId: string;
  conversationId: string;
  fileName: string;
  mimeType: string;
  fileSize: number;
}): Promise<PresignedUploadResult> {
  const { tenantId, conversationId, fileName, mimeType, fileSize } = params;

  if (!S3_CONFIG.allowedMimeTypes.includes(mimeType)) {
    throw new Error(`File type ${mimeType} is not allowed`);
  }

  const maxSize = getMaxFileSize(mimeType);
  if (fileSize > maxSize) {
    throw new Error(`File size ${fileSize} exceeds maximum ${maxSize} bytes for type ${mimeType}`);
  }

  const mediaId = uuidv4();
  const sanitizedFileName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
  const s3Key = `tenants/${tenantId}/conversations/${conversationId}/${mediaId}/${sanitizedFileName}`;

  const command = new PutObjectCommand({
    Bucket: S3_CONFIG.bucket,
    Key: s3Key,
    ContentType: mimeType,
    ContentLength: fileSize,
    ServerSideEncryption: 'AES256',
    Metadata: {
      'tenant-id': tenantId,
      'conversation-id': conversationId,
      'media-id': mediaId,
    },
  });

  const uploadUrl = await getSignedUrl(s3Client, command, {
    expiresIn: S3_CONFIG.presignedUrlExpiry,
  });

  return {
    uploadUrl,
    s3Key,
    mediaId,
    expiresIn: S3_CONFIG.presignedUrlExpiry,
  };
}

export async function generateDownloadUrl(s3Key: string): Promise<PresignedDownloadResult> {
  const command = new GetObjectCommand({
    Bucket: S3_CONFIG.bucket,
    Key: s3Key,
  });

  const downloadUrl = await getSignedUrl(s3Client, command, {
    expiresIn: S3_CONFIG.presignedUrlExpiry,
  });

  return {
    downloadUrl,
    expiresIn: S3_CONFIG.presignedUrlExpiry,
  };
}
