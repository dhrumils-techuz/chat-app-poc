import { z } from 'zod';
import { ValidationMsg } from '../constants/messages';

// Auth schemas
export const loginSchema = z.object({
  email: z.string().email(ValidationMsg.INVALID_EMAIL),
  password: z.string().min(1, ValidationMsg.PASSWORD_REQUIRED),
  deviceId: z.string().uuid(ValidationMsg.INVALID_DEVICE_ID).optional(),
  deviceName: z.string().max(100).optional(),
  platform: z.string().max(50).optional(),
  fcmToken: z.string().max(500).optional(),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, ValidationMsg.REFRESH_TOKEN_REQUIRED),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(8).max(128),
});

// User schemas
export const createUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(128),
  fullName: z.string().min(1).max(255),
  phone: z.string().max(20).optional(),
  role: z.enum(['tenant_admin', 'user']).default('user'),
});

export const updateUserSchema = z.object({
  fullName: z.string().min(1).max(255).optional(),
  phone: z.string().max(20).optional(),
  avatarUrl: z.string().url().max(2048).optional().nullable(),
  isActive: z.boolean().optional(),
});

// Conversation schemas
export const createConversationSchema = z.object({
  type: z.enum(['direct', 'group']),
  name: z.string().min(1).max(255).optional(),
  participantIds: z.array(z.string().uuid()).min(1).max(256),
});

export const updateConversationSchema = z.object({
  name: z.string().min(1).max(255).optional(),
  avatarUrl: z.string().url().max(2048).optional().nullable(),
});

export const addParticipantSchema = z.object({
  userId: z.string().uuid(),
  role: z.enum(['admin', 'member']).default('member'),
});

// Message schemas
export const sendMessageSchema = z.object({
  type: z.enum(['text', 'image', 'audio', 'document']),
  content: z.string().max(10000).optional(),
  mediaId: z.string().uuid().optional(),
  replyToId: z.string().uuid().optional(),
}).refine(
  (data) => {
    if (data.type === 'text') return !!data.content;
    return !!data.mediaId;
  },
  { message: ValidationMsg.TEXT_REQUIRES_CONTENT }
);

// Media schemas
export const requestUploadUrlSchema = z.object({
  conversationId: z.string().uuid(),
  fileName: z.string().min(1).max(255),
  mimeType: z.string().min(1).max(255),
  fileSize: z.number().int().positive(),
});

export const confirmUploadSchema = z.object({
  mediaId: z.string().uuid(),
  s3Key: z.string().min(1),
  conversationId: z.string().uuid(),
  fileName: z.string().min(1).max(255),
  mimeType: z.string().min(1).max(255),
  fileSize: z.number().int().positive(),
});

// Folder schemas
export const createFolderSchema = z.object({
  name: z.string().min(1).max(100),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
});

export const updateFolderSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional().nullable(),
  sortOrder: z.number().int().min(0).optional(),
});

export const addConversationToFolderSchema = z.object({
  conversationId: z.string().uuid(),
});

// Admin schemas
export const createTenantSchema = z.object({
  name: z.string().min(1).max(255),
  domain: z.string().max(255).optional(),
  settings: z.record(z.any()).optional(),
  adminEmail: z.string().email(),
  adminPassword: z.string().min(8).max(128),
  adminFullName: z.string().min(1).max(255),
});

// Pagination query schema
export const paginationSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  direction: z.enum(['forward', 'backward']).default('forward'),
});

// UUID param schema
export const uuidParamSchema = z.object({
  id: z.string().uuid(ValidationMsg.INVALID_ID_FORMAT),
});

export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
export type CreateUserInput = z.infer<typeof createUserSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type CreateConversationInput = z.infer<typeof createConversationSchema>;
export type UpdateConversationInput = z.infer<typeof updateConversationSchema>;
export type AddParticipantInput = z.infer<typeof addParticipantSchema>;
export type SendMessageInput = z.infer<typeof sendMessageSchema>;
export type RequestUploadUrlInput = z.infer<typeof requestUploadUrlSchema>;
export type ConfirmUploadInput = z.infer<typeof confirmUploadSchema>;
export type CreateFolderInput = z.infer<typeof createFolderSchema>;
export type UpdateFolderInput = z.infer<typeof updateFolderSchema>;
export type CreateTenantInput = z.infer<typeof createTenantSchema>;
