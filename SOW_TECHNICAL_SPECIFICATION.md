# Statement of Work (SOW) - Technical Specification
# HIPAA-Compliant Medical Chat Application

**Project**: MedChat - Enterprise Medical Sales Rep Communication Platform
**Version**: 1.0
**Date**: March 12, 2026
**Status**: In Development

---

## 1. Executive Summary

### 1.1 Project Overview
Custom-built HIPAA-compliant chat application for medical sales representatives, replacing CometChat (3rd party SDK). The application supports one-to-one and group messaging, media sharing, chat folder organization, and multi-tenant architecture for internal organization use.

### 1.2 Problem Statement
The existing CometChat-based solution hit feature development limitations due to the vendor's extended roadmap for new features, preventing timely delivery of required customizations including chat folder grouping and medical compliance requirements.

### 1.3 Solution
Full custom implementation using Flutter (cross-platform frontend), Node.js Express (backend API + real-time messaging), PostgreSQL (database), and React/Next.js (admin panel).

---

## 2. Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Frontend | Flutter + GetX | 3.x / 4.7.2 | Cross-platform mobile, tablet, desktop |
| Backend API | Node.js + Express.js | 20 LTS / 4.x | REST API server |
| Real-time | Socket.IO | 4.x | WebSocket messaging |
| Language (Backend) | TypeScript | 5.x | Type-safe backend development |
| Database | PostgreSQL | 15+ | Primary data storage |
| Cache/PubSub | Redis | 7.x | Socket.IO adapter, sessions, presence |
| File Storage | AWS S3 (SSE-KMS) | - | HIPAA-compliant media storage |
| Push Notifications | Firebase Cloud Messaging | - | Cross-platform push notifications |
| Local Database | SQLite + SQLCipher | - | Encrypted offline cache on device |
| Admin Panel | Next.js + shadcn/ui | 14.x | Web-based administration |
| Authentication | Custom JWT (RS256) | - | Email/password authentication |
| Containerization | Docker + Docker Compose | - | Development and deployment |

---

## 3. Architecture Overview

### 3.1 System Architecture
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Flutter App     │     │  Node.js Backend  │     │  Admin Panel    │
│  (Mobile/Tablet/ │◄───►│  (Express + Socket│◄───►│  (Next.js)      │
│   Desktop)       │     │   .IO)            │     │                 │
└────────┬────────┘     └────────┬─────────┘     └─────────────────┘
         │                       │
         │  TLS 1.2+            │
         │  WSS                  │
         │                       ├──► PostgreSQL (Encrypted at rest)
         │                       ├──► Redis (Encrypted at rest + in transit)
         │                       ├──► AWS S3 (SSE-KMS)
         │                       └──► Firebase Cloud Messaging
         │
         └──► SQLCipher (Local encrypted DB)
```

### 3.2 Multi-Tenant Architecture
- **Strategy**: Shared schema with `tenant_id` column on all tables
- **Isolation**: Every database query filtered by `tenant_id` extracted from JWT
- **Middleware**: `tenant.middleware.ts` injects tenant context from authenticated JWT into every request
- **Access Control**: Users can only access data within their own tenant

### 3.3 Security Architecture (HIPAA Compliance)
- **Transport Encryption**: TLS 1.2+ for all HTTP/WSS traffic
- **Database Encryption at Rest**: AWS RDS encryption (AES-256)
- **Object Storage Encryption**: S3 Server-Side Encryption with KMS (SSE-KMS)
- **Cache Encryption**: Redis with encryption at rest and in-transit
- **Client-Side Encryption**: SQLCipher (AES-256) for local database
- **Authentication**: JWT RS256 with 15-minute access tokens and 30-day refresh tokens
- **Session Management**: 15-minute inactivity auto-logout
- **Audit Logging**: Append-only audit trail for all PHI access
- **Role-Based Access Control**: super_admin, tenant_admin, user roles

---

## 4. Design System

### 4.1 UI Design Reference
Based on WhatsApp UI Kit (Figma): WhatsUp Chatting App UI Kit
- 83 screens designed for Light theme
- 428px width design viewport (iPhone-based)

### 4.2 Color Palette
| Token | Hex Value | Usage |
|-------|-----------|-------|
| Primary | `#10C17D` | Active elements, links, badges |
| Primary Gradient Start | `#10C17D` | Gradient buttons, FAB |
| Primary Gradient End | `#01F094` | Gradient buttons, FAB |
| Primary 10% | `rgba(16,193,125,0.1)` | Icon button backgrounds |
| Text Primary | `#09101D` | Headings, names |
| Text Secondary | `#545D69` | Message previews, subtitles |
| Text Tertiary | `#6D7580` | Timestamps |
| Text Light | `#858C94` | Placeholder text |
| Divider | `#DADEE3` | Line separators |
| Background | `#FFFFFF` | Screen backgrounds |
| Shadow | `rgba(90,108,234,0.08)` | Elevated element shadows |

### 4.3 Typography
| Platform | Font Family |
|----------|-------------|
| Android / Windows | Roboto |
| iOS | Source Sans Pro |

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Heading Large | 26px | SemiBold (600) | App title |
| Heading Medium | 18px | SemiBold (600) | Chat names, section titles |
| Body Medium | 16px | SemiBold (600) | Tab labels, buttons |
| Body Small | 14px | Regular (400) | Message preview, timestamps |
| Caption | 11px | Regular (400) | Badge counts |

### 4.4 Component Specifications
| Component | Dimensions | Style |
|-----------|-----------|-------|
| Avatar (chat list) | 64x64px | Circular |
| Avatar (profile) | 72-100px | Circular |
| Icon Button | 40x40px | 12px border-radius, primary 10% bg |
| Floating Action Button | 60x60px | Circular, gradient bg |
| Unread Badge | 25x25px | Circular, gradient bg, white text |
| Tab Indicator | 3px height | Gradient bg, 2px radius |
| Chat List Item Gap | 20px | Vertical spacing between items |
| Screen Padding | 24px | Horizontal padding |
| Navbar Height | 48px | 12px top padding |

### 4.5 Message Bubble Design
- **Sent Messages**: Right-aligned, light green-tinted background, timestamp + blue double-check marks
- **Received Messages**: Left-aligned, light grey background, timestamp only
- **Group Messages**: Sender name displayed in green (`#10C17D`) above message text
- **Voice Messages**: Waveform visualization with play/pause controls
- **Media Messages**: Thumbnail preview with download indicator

---

## 5. Database Schema

### 5.1 Entity Relationship Summary

| Table | Description | Key Relationships |
|-------|-------------|-------------------|
| `tenants` | Organization entities | Parent of all tenant-scoped data |
| `users` | User accounts | Belongs to tenant, has many devices |
| `devices` | User devices (FCM) | Belongs to user |
| `conversations` | Chat threads | Has many participants and messages |
| `conversation_participants` | Chat membership | Links users to conversations |
| `messages` | Chat messages | Belongs to conversation and sender |
| `message_status` | Delivery/read receipts | Per-user status per message |
| `media` | File attachments | Belongs to message, stored in S3 |
| `chat_folders` | Logical chat grouping | Admin-defined or user-defined |
| `chat_folder_conversations` | Folder-chat mapping | Links folders to conversations |
| `refresh_tokens` | Auth refresh tokens | Belongs to user and device |
| `audit_logs` | HIPAA audit trail | Append-only, references user and tenant |

### 5.2 Table Definitions

#### tenants
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY, auto-generated |
| name | VARCHAR(255) | NOT NULL |
| slug | VARCHAR(100) | UNIQUE, NOT NULL |
| settings | JSONB | DEFAULT '{}' |
| is_active | BOOLEAN | DEFAULT true |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

#### users
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY, auto-generated |
| tenant_id | UUID | FK -> tenants(id), NOT NULL |
| email | VARCHAR(255) | NOT NULL, UNIQUE per tenant |
| password_hash | VARCHAR(255) | NOT NULL (bcrypt) |
| name | VARCHAR(255) | NOT NULL |
| phone | VARCHAR(50) | NULLABLE |
| avatar_url | VARCHAR(512) | NULLABLE |
| role | VARCHAR(50) | DEFAULT 'user' (super_admin/tenant_admin/user) |
| status | VARCHAR(20) | DEFAULT 'active' (active/suspended/deactivated) |
| last_seen_at | TIMESTAMPTZ | NULLABLE |
| is_online | BOOLEAN | DEFAULT false |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

#### devices
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY |
| user_id | UUID | FK -> users(id) ON DELETE CASCADE |
| tenant_id | UUID | FK -> tenants(id) |
| device_type | VARCHAR(20) | NOT NULL (android/ios/windows/web) |
| fcm_token | VARCHAR(512) | NULLABLE |
| device_info | JSONB | DEFAULT '{}' |
| is_active | BOOLEAN | DEFAULT true |
| last_active_at | TIMESTAMPTZ | DEFAULT NOW() |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

#### conversations
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY |
| tenant_id | UUID | FK -> tenants(id) |
| type | VARCHAR(20) | DEFAULT 'private' (private/group) |
| name | VARCHAR(255) | NULLABLE (required for group) |
| description | TEXT | NULLABLE |
| avatar_url | VARCHAR(512) | NULLABLE |
| created_by | UUID | FK -> users(id) |
| last_message_id | UUID | NULLABLE (denormalized) |
| last_message_at | TIMESTAMPTZ | NULLABLE |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

#### conversation_participants
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY |
| conversation_id | UUID | FK -> conversations(id) ON DELETE CASCADE |
| user_id | UUID | FK -> users(id) ON DELETE CASCADE |
| tenant_id | UUID | FK -> tenants(id) |
| role | VARCHAR(20) | DEFAULT 'member' (admin/member) |
| is_muted | BOOLEAN | DEFAULT false |
| unread_count | INTEGER | DEFAULT 0 |
| last_read_message_id | UUID | NULLABLE |
| joined_at | TIMESTAMPTZ | DEFAULT NOW() |
| left_at | TIMESTAMPTZ | NULLABLE |
| | | UNIQUE(conversation_id, user_id) |

#### messages
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY |
| conversation_id | UUID | FK -> conversations(id) |
| sender_id | UUID | FK -> users(id) |
| tenant_id | UUID | FK -> tenants(id) |
| type | VARCHAR(20) | DEFAULT 'text' (text/image/audio/document/file/system) |
| content | TEXT | NULLABLE |
| reply_to_id | UUID | FK -> messages(id), NULLABLE |
| is_deleted | BOOLEAN | DEFAULT false |
| deleted_for | UUID[] | Array of user IDs |
| deleted_for_everyone | BOOLEAN | DEFAULT false |
| deleted_at | TIMESTAMPTZ | NULLABLE |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

#### message_status
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY |
| message_id | UUID | FK -> messages(id) ON DELETE CASCADE |
| user_id | UUID | FK -> users(id) |
| tenant_id | UUID | FK -> tenants(id) |
| status | VARCHAR(20) | DEFAULT 'sent' (sent/delivered/read) |
| delivered_at | TIMESTAMPTZ | NULLABLE |
| read_at | TIMESTAMPTZ | NULLABLE |
| | | UNIQUE(message_id, user_id) |

#### media
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY |
| message_id | UUID | FK -> messages(id) ON DELETE CASCADE |
| tenant_id | UUID | FK -> tenants(id) |
| type | VARCHAR(20) | NOT NULL (image/audio/document/file) |
| file_name | VARCHAR(255) | NOT NULL |
| file_size | BIGINT | NOT NULL (bytes) |
| mime_type | VARCHAR(100) | NOT NULL |
| s3_key | VARCHAR(512) | NOT NULL |
| s3_bucket | VARCHAR(255) | NOT NULL |
| thumbnail_s3_key | VARCHAR(512) | NULLABLE |
| duration_seconds | INTEGER | NULLABLE (audio) |
| width | INTEGER | NULLABLE (images) |
| height | INTEGER | NULLABLE (images) |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

#### chat_folders
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY |
| tenant_id | UUID | FK -> tenants(id) |
| user_id | UUID | FK -> users(id), NULLABLE (NULL = admin-defined) |
| name | VARCHAR(100) | NOT NULL |
| icon | VARCHAR(50) | NULLABLE |
| sort_order | INTEGER | DEFAULT 0 |
| type | VARCHAR(20) | DEFAULT 'user' (admin/user) |
| is_default | BOOLEAN | DEFAULT false |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() |

#### chat_folder_conversations
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY |
| folder_id | UUID | FK -> chat_folders(id) ON DELETE CASCADE |
| conversation_id | UUID | FK -> conversations(id) ON DELETE CASCADE |
| user_id | UUID | FK -> users(id) |
| tenant_id | UUID | FK -> tenants(id) |
| | | UNIQUE(folder_id, conversation_id, user_id) |

#### refresh_tokens
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY |
| user_id | UUID | FK -> users(id) ON DELETE CASCADE |
| tenant_id | UUID | FK -> tenants(id) |
| token_hash | VARCHAR(255) | NOT NULL (SHA-256) |
| device_id | UUID | FK -> devices(id) |
| expires_at | TIMESTAMPTZ | NOT NULL |
| is_revoked | BOOLEAN | DEFAULT false |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

#### audit_logs (HIPAA - Append Only)
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY |
| tenant_id | UUID | FK -> tenants(id) |
| user_id | UUID | FK -> users(id), NULLABLE |
| action | VARCHAR(100) | NOT NULL |
| resource_type | VARCHAR(50) | NULLABLE |
| resource_id | UUID | NULLABLE |
| ip_address | INET | NULLABLE |
| user_agent | VARCHAR(512) | NULLABLE |
| request_id | UUID | NULLABLE |
| metadata | JSONB | DEFAULT '{}' |
| created_at | TIMESTAMPTZ | DEFAULT NOW() |

### 5.3 Database Indexes
- `idx_users_tenant`: users(tenant_id)
- `idx_users_email`: users(tenant_id, email)
- `idx_devices_user`: devices(user_id)
- `idx_conversations_tenant`: conversations(tenant_id)
- `idx_conversations_last_msg`: conversations(tenant_id, last_message_at DESC)
- `idx_cp_user`: conversation_participants(user_id, left_at)
- `idx_cp_conversation`: conversation_participants(conversation_id)
- `idx_messages_conversation`: messages(conversation_id, created_at DESC)
- `idx_messages_sender`: messages(sender_id)
- `idx_message_status_message`: message_status(message_id)
- `idx_media_message`: media(message_id)
- `idx_folders_tenant`: chat_folders(tenant_id)
- `idx_folders_user`: chat_folders(user_id)
- `idx_refresh_tokens_user`: refresh_tokens(user_id)
- `idx_audit_tenant_time`: audit_logs(tenant_id, created_at DESC)
- `idx_audit_user`: audit_logs(user_id, created_at DESC)
- `idx_audit_action`: audit_logs(action)

---

## 6. API Specification

### 6.1 Authentication Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/register` | Admin-initiated user registration | Yes (admin) |
| POST | `/api/auth/login` | Email/password login | No |
| POST | `/api/auth/refresh` | Refresh access token | No (refresh token) |
| POST | `/api/auth/logout` | Revoke refresh token | Yes |
| POST | `/api/auth/change-password` | Change own password | Yes |
| POST | `/api/auth/forgot-password` | Initiate password reset | No |
| POST | `/api/auth/reset-password` | Complete password reset | No (reset token) |

### 6.2 User Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/users` | List users in tenant (paginated) | Yes |
| GET | `/api/users/:id` | Get user profile | Yes |
| PUT | `/api/users/:id` | Update own profile | Yes |
| GET | `/api/users/:id/presence` | Get user online status | Yes |

### 6.3 Conversation Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/conversations` | List conversations for current user | Yes |
| POST | `/api/conversations` | Create conversation (private/group) | Yes |
| GET | `/api/conversations/:id` | Get conversation details | Yes |
| PUT | `/api/conversations/:id` | Update group info | Yes |
| DELETE | `/api/conversations/:id` | Leave/delete conversation | Yes |
| GET | `/api/conversations/:id/participants` | List participants | Yes |
| POST | `/api/conversations/:id/participants` | Add participants (group) | Yes |
| DELETE | `/api/conversations/:id/participants/:userId` | Remove participant | Yes |
| PUT | `/api/conversations/:id/mute` | Mute/unmute | Yes |

### 6.4 Message Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/conversations/:id/messages` | Paginated messages (cursor-based) | Yes |
| POST | `/api/conversations/:id/messages` | Send message (REST fallback) | Yes |
| DELETE | `/api/messages/:id` | Delete message | Yes |
| PUT | `/api/messages/:id/read` | Mark as read (REST fallback) | Yes |

### 6.5 Media Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/media/upload-url` | Get pre-signed S3 upload URL | Yes |
| GET | `/api/media/:id/download-url` | Get pre-signed S3 download URL | Yes |

### 6.6 Folder Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/folders` | List folders (admin + user's own) | Yes |
| POST | `/api/folders` | Create folder | Yes |
| PUT | `/api/folders/:id` | Update folder | Yes |
| DELETE | `/api/folders/:id` | Delete folder | Yes |
| POST | `/api/folders/:id/conversations` | Add conversation to folder | Yes |
| DELETE | `/api/folders/:id/conversations/:conversationId` | Remove conversation | Yes |

### 6.7 Admin Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/admin/users` | List all users (super_admin cross-tenant) | Yes (admin) |
| POST | `/api/admin/users` | Create/invite user | Yes (admin) |
| PUT | `/api/admin/users/:id/status` | Activate/suspend/deactivate | Yes (admin) |
| GET | `/api/admin/audit-logs` | Query audit logs | Yes (admin) |
| GET | `/api/admin/tenants` | List tenants | Yes (super_admin) |
| POST | `/api/admin/tenants` | Create tenant | Yes (super_admin) |
| PUT | `/api/admin/tenants/:id` | Update tenant | Yes (super_admin) |
| POST | `/api/admin/folders` | Create admin-defined folder | Yes (admin) |
| GET | `/api/admin/stats` | Dashboard statistics | Yes (admin) |

### 6.8 Health Endpoint
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/health` | Health check (DB, Redis, S3) | No |

---

## 7. Real-Time Messaging (Socket.IO)

### 7.1 Client-to-Server Events
| Event | Payload | Description |
|-------|---------|-------------|
| `message:send` | `{ conversationId, tempId, type, content, mediaId?, replyToId? }` | Send new message |
| `message:delivered` | `{ messageId, conversationId }` | Confirm delivery |
| `message:read` | `{ messageId, conversationId }` | Confirm read |
| `typing:start` | `{ conversationId }` | Start typing indicator |
| `typing:stop` | `{ conversationId }` | Stop typing indicator |
| `presence:online` | `{}` | User came online |
| `presence:offline` | `{}` | User going offline |
| `conversation:join` | `{ conversationId }` | Join socket room |
| `conversation:leave` | `{ conversationId }` | Leave socket room |

### 7.2 Server-to-Client Events
| Event | Payload | Description |
|-------|---------|-------------|
| `message:new` | `{ message object }` | New message for room members |
| `message:sent` | `{ tempId, messageId, createdAt }` | Server acknowledgment to sender |
| `message:delivered` | `{ messageId, userId, deliveredAt }` | Delivery confirmation |
| `message:read` | `{ messageId, userId, readAt }` | Read confirmation |
| `message:deleted` | `{ messageId, deletedForEveryone }` | Message deletion notification |
| `typing:indicator` | `{ conversationId, userId, isTyping }` | Typing status |
| `presence:update` | `{ userId, isOnline, lastSeenAt }` | Presence change |
| `error` | `{ code, message }` | Error notification |

---

## 8. Authentication & Authorization

### 8.1 Authentication Flow
1. User submits email + password to `POST /api/auth/login`
2. Server validates via bcrypt, generates JWT access token (RS256, 15-min) and refresh token (30-day)
3. Client stores access token in memory, refresh token in flutter_secure_storage
4. Dio interceptor adds `Authorization: Bearer <accessToken>` to all requests
5. On 401: interceptor calls `/api/auth/refresh`, retries original request
6. Socket.IO connects with access token in handshake auth
7. 15-minute inactivity auto-logout (HIPAA requirement)

### 8.2 Role-Based Access Control
| Role | Permissions |
|------|------------|
| `super_admin` | Full system access across all tenants |
| `tenant_admin` | Manage users, folders, view audit logs within own tenant |
| `user` | Standard chat access within own tenant |

### 8.3 Security Policies
- **Password Complexity**: Minimum 8 characters, uppercase, lowercase, number, special character
- **Failed Login Lockout**: 5 attempts -> 15-minute lockout
- **Token Rotation**: Refresh tokens are single-use (rotated on each refresh)
- **Device Tracking**: Each login creates/updates a device record for FCM management

---

## 9. File Storage & Media

### 9.1 Supported File Types
| Category | MIME Types | Max Size |
|----------|-----------|----------|
| Images | image/jpeg, image/png, image/webp | 16 MB |
| Audio | audio/aac, audio/m4a, audio/mpeg | 25 MB |
| Documents | application/pdf, application/msword, application/vnd.openxmlformats-* | 100 MB |
| Spreadsheets | application/vnd.ms-excel, application/vnd.openxmlformats-* | 100 MB |

### 9.2 Upload Flow
1. Client requests pre-signed upload URL from `POST /api/media/upload-url`
2. Server validates file type/size, generates S3 key: `tenants/{tenantId}/conversations/{conversationId}/{uuid}/{filename}`
3. Server returns `{ uploadUrl, s3Key, mediaId }`
4. Client uploads file directly to S3 via PUT to pre-signed URL (HTTPS)
5. Client sends message via Socket.IO with mediaId
6. S3 handles encryption at rest (SSE-KMS)

### 9.3 Download Flow
1. Client requests download URL from `GET /api/media/:id/download-url`
2. Server verifies user is conversation participant, creates audit log
3. Server returns time-limited (15-min) pre-signed GET URL
4. Client downloads and caches locally in encrypted SQLCipher path

### 9.4 Image Processing
- **Compression**: Max 1920px longest edge, JPEG quality 80
- **Thumbnails**: 300x300px, JPEG quality 60, generated client-side

---

## 10. Chat Folders Feature

### 10.1 Folder Types
| Type | Created By | Visible To | Editable By |
|------|-----------|------------|-------------|
| `admin` | Tenant admin (via admin panel) | All users in tenant | Tenant admin only |
| `user` | Individual user | Only that user | That user only |

### 10.2 Folder Behavior
- "All Chats" is the default folder (always present, shows all conversations)
- Admin-defined folders appear first, sorted by `sort_order`
- User-defined folders appear after admin folders
- A conversation can belong to multiple folders
- Folders display as horizontal scrollable tabs above the chat list
- Users can drag/assign conversations to their personal folders

---

## 11. Responsive Design Strategy

### 11.1 Breakpoints
| Device | Width | Layout |
|--------|-------|--------|
| Mobile Phone | < 600px | Single screen navigation |
| Tablet | 600-900px | Split view (list + detail) |
| Desktop | >= 900px | Split view (list + detail) |

### 11.2 Layout Behavior
| Screen | Mobile | Tablet/Desktop |
|--------|--------|---------------|
| Chat List + Detail | Separate screens via navigation push | Side-by-side: left panel (350px) + right panel |
| Group Info | Full screen push | Right panel or modal |
| Settings/Profile | Full screen push | Dialog or slide-over |
| Create Group | Full screen push | Dialog overlay |
| Media Viewer | Full screen push | Modal overlay |

### 11.3 Implementation
- Separate view files for Chat List and Chat Detail (mobile vs desktop)
- Single adaptive widget for all other screens
- `AdaptiveLayout` widget manages the split-panel rendering
- Platform detection via `MediaQuery.of(context).size.width`

---

## 12. Offline Support

### 12.1 Local Database (SQLCipher)
- Messages cached in `local_messages` table
- Conversations cached in `local_conversations` table
- User directory cached in `local_users` table
- Offline message queue in `local_offline_queue` table

### 12.2 Offline Queue
- Messages sent while offline are saved with `sync_status = 'pending'`
- On reconnection, queue is flushed in chronological order
- Failed messages (after 3 retries) marked as `failed` with retry UI
- Read receipts and typing indicators also queued

### 12.3 Sync Strategy
- Cursor-based pagination: `created_at|id` composite cursor
- On app open: sync conversations list, then messages for visible conversations
- On reconnect: request missed messages since `last_synced_at`
- Local DB is cache only; server is source of truth

---

## 13. Push Notifications

### 13.1 Platform Support
| Platform | Service | Notes |
|----------|---------|-------|
| Android | Firebase Cloud Messaging | Native support |
| iOS | FCM + APNs | FCM bridges to APNs |
| Windows | FCM (limited) | Polling fallback if WNS unavailable |

### 13.2 HIPAA-Compliant Notification Payload
```json
{
  "notification": {
    "title": "New message from John",
    "body": "You have a new message"
  },
  "data": {
    "conversationId": "uuid",
    "type": "new_message"
  }
}
```
**No PHI in push payload** - actual message content fetched from server after notification tap.

---

## 14. HIPAA Compliance Checklist

| Requirement | Implementation | Status |
|-------------|---------------|--------|
| Encryption at rest (server) | PostgreSQL RDS encryption, S3 SSE-KMS, Redis encryption | Planned |
| Encryption at rest (client) | SQLCipher AES-256, key in platform keychain | Planned |
| Encryption in transit | TLS 1.2+ for HTTP/WSS, HTTPS for S3 | Planned |
| Access controls (RBAC) | super_admin, tenant_admin, user roles via middleware | Planned |
| Tenant data isolation | tenant_id filtering on all queries | Planned |
| Audit logging | Append-only audit_logs table, all PHI access logged | Planned |
| Session management | 15-min access token, 15-min inactivity timeout | Planned |
| Password policy | 8+ chars, complexity requirements, 5-attempt lockout | Planned |
| Push notification safety | No PHI in FCM payload | Planned |
| Screenshot prevention | FLAG_SECURE (Android), configurable per tenant | Planned |
| No PHI in logs | Server logs sanitized, message content never logged | Planned |
| Data retention | 6-year minimum for audit logs (HIPAA requirement) | Planned |
| AWS BAA | Required for S3, RDS, ElastiCache | Planned |
| Secure data deletion | Soft delete with audit trail, S3 object deletion | Planned |

---

## 15. Development Phases

### Phase 1: Foundation
- Backend: Express.js setup, PostgreSQL migrations, auth service, middleware
- Flutter: JWT auth module, token management, sign-in screen
- **Deliverable**: Working email/password login with JWT tokens

### Phase 2: Core Messaging
- Backend: Socket.IO server, message/conversation endpoints
- Flutter: Chat list, chat detail, real-time messaging, receipts, typing, presence
- Flutter: SQLCipher local DB, responsive split view
- **Deliverable**: Real-time text messaging on all platforms

### Phase 3: Media & Files
- Backend: S3 pre-signed URLs, file validation
- Flutter: Image/audio/document picker, upload/download, media bubbles
- **Deliverable**: Full media sharing capability

### Phase 4: Groups & Folders
- Backend: Group CRUD, folder CRUD
- Flutter: Group creation/management, folder tabs, folder management
- **Deliverable**: Group chats and chat organization

### Phase 5: Notifications & Offline
- Backend: FCM integration
- Flutter: Push notifications, offline queue, message sync
- **Deliverable**: Offline-capable with push notifications

### Phase 6: Admin Panel & HIPAA Hardening
- Admin: Next.js dashboard, user/tenant management, audit viewer
- Security: Certificate pinning, screenshot prevention, lockout
- **Deliverable**: Admin panel and hardened security

### Phase 7: Polish & Testing
- Message deletion, UI animations, search, tests, performance
- **Deliverable**: Production-ready application

---

## 16. Supported Platforms

| Platform | Version | Priority |
|----------|---------|----------|
| Android | 6.0+ (API 23) | Phase 1 |
| iOS | 13.0+ | Phase 1 |
| Windows | 10+ | Phase 1 |
| Android Tablet | 6.0+ | Phase 1 (responsive) |
| iPad | 13.0+ | Phase 1 (responsive) |

---

## 17. Dependencies

### 17.1 Flutter Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| get | ^4.7.2 | State management, routing, DI |
| dio | ^5.7.0 | HTTP client |
| socket_io_client | ^2.0.0 | Socket.IO client |
| sqflite_sqlcipher | ^3.0.0 | Encrypted SQLite |
| firebase_core | latest | Firebase initialization |
| firebase_messaging | latest | Push notifications |
| flutter_secure_storage | latest | Secure credential storage |
| flutter_image_compress | latest | Image compression |
| record | latest | Audio recording |
| file_picker | latest | Document/file selection |
| cached_network_image | latest | Image caching |
| uuid | latest | UUID generation |
| path_provider | latest | File system paths |
| open_filex | latest | Open files with system app |
| connectivity_plus | ^6.1.3 | Network status |
| intl | ^0.19.0 | Date/time formatting |
| flutter_svg | ^2.0.17 | SVG rendering |

### 17.2 Backend Dependencies
| Package | Purpose |
|---------|---------|
| express | HTTP server |
| socket.io | Real-time messaging |
| pg / pg-pool | PostgreSQL client |
| ioredis | Redis client |
| bcrypt | Password hashing |
| jsonwebtoken | JWT signing/verification |
| @aws-sdk/client-s3 | AWS S3 operations |
| firebase-admin | FCM push notifications |
| multer | File upload handling |
| helmet | HTTP security headers |
| cors | Cross-origin resource sharing |
| express-rate-limit | Rate limiting |
| winston | Structured logging |
| zod | Request validation |
| dotenv | Environment variables |
| uuid | UUID generation |

---

*This document will be updated throughout the development journey as specifications evolve.*
