/**
 * Centralized string constants for the server.
 * All user-facing messages, error messages, and status strings are defined here.
 */

// ──────────────────────────────────────────────
// Error Codes
// ──────────────────────────────────────────────
export const ErrorCode = {
  BAD_REQUEST: 'BAD_REQUEST',
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  CONFLICT: 'CONFLICT',
  TOO_MANY_REQUESTS: 'TOO_MANY_REQUESTS',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  VALIDATION_ERROR: 'VALIDATION_ERROR',

  // Auth
  AUTH_TOKEN_MISSING: 'AUTH_TOKEN_MISSING',
  AUTH_TOKEN_EXPIRED: 'AUTH_TOKEN_EXPIRED',
  AUTH_TOKEN_INVALID: 'AUTH_TOKEN_INVALID',
  AUTH_ERROR: 'AUTH_ERROR',
  AUTH_REQUIRED: 'AUTH_REQUIRED',
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  ACCOUNT_LOCKED: 'ACCOUNT_LOCKED',
  TOKEN_REVOKED: 'TOKEN_REVOKED',
  INVALID_REFRESH_TOKEN: 'INVALID_REFRESH_TOKEN',
  REFRESH_TOKEN_EXPIRED: 'REFRESH_TOKEN_EXPIRED',
  USER_INACTIVE: 'USER_INACTIVE',
  WEAK_PASSWORD: 'WEAK_PASSWORD',
  EMAIL_EXISTS: 'EMAIL_EXISTS',
  INVALID_PASSWORD: 'INVALID_PASSWORD',
  INVALID_FILE_TYPE: 'INVALID_FILE_TYPE',
  TENANT_MISSING: 'TENANT_MISSING',

  // Rate Limiting
  RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
  AUTH_RATE_LIMIT_EXCEEDED: 'AUTH_RATE_LIMIT_EXCEEDED',
  UPLOAD_RATE_LIMIT_EXCEEDED: 'UPLOAD_RATE_LIMIT_EXCEEDED',
} as const;

// ──────────────────────────────────────────────
// Auth Messages
// ──────────────────────────────────────────────
export const AuthMsg = {
  LOGGED_OUT: 'Logged out successfully',
  PASSWORD_CHANGED: 'Password changed successfully. Please log in again.',
  AUTHENTICATION_REQUIRED: 'Authentication required',
  TOKEN_EXPIRED: 'Token expired',
  INVALID_TOKEN: 'Invalid token',
  INVALID_REFRESH_TOKEN: 'Invalid refresh token',
  TOKEN_REVOKED: 'Token has been revoked. Please log in again.',
  REFRESH_TOKEN_EXPIRED: 'Refresh token expired',
  INVALID_CREDENTIALS: 'Invalid email or password',
  ACCOUNT_LOCKED: 'Account temporarily locked due to failed login attempts. Try again in 15 minutes.',
  USER_NOT_FOUND_OR_INACTIVE: 'User not found or inactive',
  CURRENT_PASSWORD_INCORRECT: 'Current password is incorrect',
  INSUFFICIENT_PERMISSIONS: 'Insufficient permissions',
  TENANT_CONTEXT_REQUIRED: 'Tenant context required',
} as const;

// ──────────────────────────────────────────────
// Validation Messages (Zod schemas)
// ──────────────────────────────────────────────
export const ValidationMsg = {
  INVALID_EMAIL: 'Invalid email address',
  PASSWORD_REQUIRED: 'Password is required',
  INVALID_DEVICE_ID: 'Invalid device ID',
  REFRESH_TOKEN_REQUIRED: 'Refresh token is required',
  INVALID_ID_FORMAT: 'Invalid ID format',
  TEXT_REQUIRES_CONTENT: 'Text messages require content; media messages require mediaId',
  VALIDATION_FAILED: 'Validation failed',
} as const;

// ──────────────────────────────────────────────
// User Messages
// ──────────────────────────────────────────────
export const UserMsg = {
  NOT_FOUND: 'User not found',
  EMAIL_EXISTS: 'A user with this email already exists in this organization',
  SEARCH_QUERY_REQUIRED: 'Search query is required',
  NOT_FOUND_IN_ORG: 'User not found in this organization',
} as const;

// ──────────────────────────────────────────────
// Conversation Messages
// ──────────────────────────────────────────────
export const ConversationMsg = {
  NOT_FOUND: 'Conversation not found',
  CANNOT_CHAT_SELF: 'Cannot create a conversation with yourself',
  DIRECT_REQUIRES_ONE: 'Direct conversations require exactly one other participant',
  PARTICIPANTS_NOT_FOUND: 'One or more participants not found in this organization',
  NOT_A_PARTICIPANT: 'You are not a participant of this conversation',
  ONLY_ADMINS_CAN_UPDATE: 'Only conversation admins can update the conversation',
  ONLY_ADMINS_CAN_ADD: 'Only conversation admins can add participants',
  ONLY_GROUP_ADD: 'Can only add participants to group conversations',
  ALREADY_PARTICIPANT: 'User is already a participant',
  INSUFFICIENT_REMOVE_PERMS: 'Insufficient permissions to remove participants',
  NO_FIELDS_TO_UPDATE: 'No fields to update',
  PARTICIPANT_ADDED: 'Participant added',
  PARTICIPANT_REMOVED: 'Participant removed',
  MISSING_REQUIRED_PARAMS: 'Missing required parameters',
  CONVERSATION_ID_REQUIRED: 'Conversation ID required',
  CONVERSATION_AND_MESSAGE_ID_REQUIRED: 'Conversation ID and Message ID required',
  DELETED: 'Conversation deleted',
  MUTED: 'Conversation muted',
  UNMUTED: 'Conversation unmuted',
  PINNED: 'Conversation pinned',
  UNPINNED: 'Conversation unpinned',
  ARCHIVED: 'Conversation archived',
  UNARCHIVED: 'Conversation unarchived',
} as const;

// ──────────────────────────────────────────────
// Message Messages
// ──────────────────────────────────────────────
export const MessageMsg = {
  NOT_FOUND: 'Message not found',
  REPLY_NOT_FOUND: 'Reply target message not found',
  NOT_FOUND_OR_NOT_SENDER: 'Message not found or you are not the sender',
  DELETED: 'Message deleted',
  MARKED_AS_READ: 'Marked as read',
  MARKED_AS_DELIVERED: 'Marked as delivered',
} as const;

// ──────────────────────────────────────────────
// Folder Messages
// ──────────────────────────────────────────────
export const FolderMsg = {
  NOT_FOUND: 'Folder not found',
  DELETED: 'Folder deleted',
  CONVERSATION_ADDED: 'Conversation added to folder',
  CONVERSATION_REMOVED: 'Conversation removed from folder',
  CONVERSATION_ALREADY_IN: 'Conversation already in folder',
  CONVERSATION_NOT_IN: 'Conversation not found in folder',
} as const;

// ──────────────────────────────────────────────
// Media Messages
// ──────────────────────────────────────────────
export const MediaMsg = {
  NOT_FOUND: 'Media not found',
  NO_ACCESS: 'You do not have access to this media',
  INVALID_FILE_TYPE: (mimeType: string) => `File type ${mimeType} is not allowed`,
} as const;

// ──────────────────────────────────────────────
// Tenant / Admin Messages
// ──────────────────────────────────────────────
export const TenantMsg = {
  NOT_FOUND: 'Tenant not found',
  NAME_EXISTS: 'A tenant with this name already exists',
} as const;

// ──────────────────────────────────────────────
// Rate Limit Messages
// ──────────────────────────────────────────────
export const RateLimitMsg = {
  TOO_MANY_REQUESTS: 'Too many requests, please try again later',
  TOO_MANY_AUTH_ATTEMPTS: 'Too many authentication attempts, please try again later',
  UPLOAD_LIMIT_EXCEEDED: 'Upload limit exceeded, please try again later',
} as const;

// ──────────────────────────────────────────────
// Error Handler Messages
// ──────────────────────────────────────────────
export const ErrorMsg = {
  INTERNAL_SERVER_ERROR: 'Internal server error',
  NOT_FOUND: 'Not found',
} as const;

// ──────────────────────────────────────────────
// Password Validation Messages
// ──────────────────────────────────────────────
export const PasswordMsg = {
  MIN_LENGTH: 'Password must be at least 8 characters long',
  LOWERCASE_REQUIRED: 'Password must contain at least one lowercase letter',
  UPPERCASE_REQUIRED: 'Password must contain at least one uppercase letter',
  NUMBER_REQUIRED: 'Password must contain at least one number',
  SPECIAL_CHAR_REQUIRED: 'Password must contain at least one special character',
  MEETS_REQUIREMENTS: 'Password meets complexity requirements',
} as const;

// ──────────────────────────────────────────────
// Health Check Statuses
// ──────────────────────────────────────────────
export const HealthStatus = {
  HEALTHY: 'healthy',
  DEGRADED: 'degraded',
  UP: 'up',
  DOWN: 'down',
  READY: 'ready',
  NOT_READY: 'not ready',
  ALIVE: 'alive',
} as const;
