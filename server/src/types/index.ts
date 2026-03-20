export type UserRole = 'super_admin' | 'tenant_admin' | 'user';

export type MessageType = 'text' | 'image' | 'audio' | 'document' | 'system';

export type ConversationType = 'direct' | 'group';

export type ParticipantRole = 'owner' | 'admin' | 'member';

export type MessageStatusType = 'sent' | 'delivered' | 'read' | 'deleted';

export type PresenceStatus = 'online' | 'offline' | 'away';

export type AuditAction =
  | 'LOGIN'
  | 'LOGOUT'
  | 'LOGIN_FAILED'
  | 'TOKEN_REFRESH'
  | 'USER_CREATE'
  | 'USER_UPDATE'
  | 'USER_DELETE'
  | 'PASSWORD_CHANGE'
  | 'MESSAGE_SEND'
  | 'MESSAGE_READ'
  | 'MEDIA_UPLOAD'
  | 'MEDIA_DOWNLOAD'
  | 'CONVERSATION_CREATE'
  | 'CONVERSATION_UPDATE'
  | 'PARTICIPANT_ADD'
  | 'PARTICIPANT_REMOVE'
  | 'CONVERSATION_DELETE'
  | 'FOLDER_CREATE'
  | 'FOLDER_UPDATE'
  | 'FOLDER_DELETE'
  | 'ADMIN_ACCESS';

export interface Tenant {
  id: string;
  name: string;
  domain: string | null;
  settings: Record<string, any>;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface User {
  id: string;
  tenant_id: string;
  email: string;
  password_hash: string;
  full_name: string;
  avatar_url: string | null;
  phone: string | null;
  role: UserRole;
  is_active: boolean;
  last_seen_at: Date | null;
  failed_login_attempts: number;
  locked_until: Date | null;
  created_at: Date;
  updated_at: Date;
}

export interface UserPublic {
  id: string;
  tenant_id: string;
  email: string;
  full_name: string;
  avatar_url: string | null;
  phone: string | null;
  role: UserRole;
  is_active: boolean;
  last_seen_at: Date | null;
  created_at: Date;
}

export interface Device {
  id: string;
  user_id: string;
  device_name: string | null;
  platform: string | null;
  fcm_token: string | null;
  is_active: boolean;
  last_active_at: Date;
  created_at: Date;
}

export interface Conversation {
  id: string;
  tenant_id: string;
  type: ConversationType;
  name: string | null;
  avatar_url: string | null;
  created_by: string;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface ConversationParticipant {
  id: string;
  conversation_id: string;
  user_id: string;
  role: ParticipantRole;
  joined_at: Date;
  left_at: Date | null;
  is_muted: boolean;
  is_pinned: boolean;
  is_archived: boolean;
  last_read_message_id: string | null;
  unread_count: number;
}

export interface Message {
  id: string;
  conversation_id: string;
  sender_id: string;
  type: MessageType;
  content: string | null;
  media_id: string | null;
  reply_to_id: string | null;
  is_deleted: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface MessageStatus {
  id: string;
  message_id: string;
  user_id: string;
  status: MessageStatusType;
  timestamp: Date;
}

export interface Media {
  id: string;
  tenant_id: string;
  conversation_id: string;
  uploaded_by: string;
  file_name: string;
  mime_type: string;
  file_size: number;
  s3_key: string;
  created_at: Date;
}

export interface ChatFolder {
  id: string;
  tenant_id: string;
  user_id: string;
  name: string;
  color: string | null;
  sort_order: number;
  created_at: Date;
  updated_at: Date;
}

export interface ChatFolderConversation {
  id: string;
  folder_id: string;
  conversation_id: string;
  added_at: Date;
}

export interface RefreshToken {
  id: string;
  user_id: string;
  device_id: string;
  token_hash: string;
  expires_at: Date;
  revoked_at: Date | null;
  created_at: Date;
}

export interface AuditLog {
  id: string;
  tenant_id: string | null;
  user_id: string | null;
  action: AuditAction;
  resource_type: string;
  resource_id: string | null;
  ip_address: string | null;
  user_agent: string | null;
  request_id: string | null;
  metadata: Record<string, any>;
  created_at: Date;
}

export interface JwtPayload {
  userId: string;
  tenantId: string;
  role: UserRole;
  deviceId: string;
  iat?: number;
  exp?: number;
}

export interface PaginationParams {
  cursor?: string;
  limit: number;
  direction: 'forward' | 'backward';
}

export interface PaginatedResult<T> {
  data: T[];
  nextCursor: string | null;
  prevCursor: string | null;
  hasMore: boolean;
}

export interface AuthenticatedRequest {
  userId: string;
  tenantId: string;
  role: UserRole;
  deviceId: string;
  requestId: string;
}

declare global {
  namespace Express {
    interface Request {
      auth?: AuthenticatedRequest;
    }
  }
}
