# MedChat — HIPAA-Compliant Medical Chat Application

A WhatsApp-style secure messaging platform for medical sales representatives, built with Flutter (mobile/desktop) and Node.js (backend). Designed for HIPAA compliance with transport encryption (TLS), at-rest encryption (AES-256/SSE-KMS), and comprehensive audit logging.

## Architecture

```
┌─────────────────────┐     ┌───────────────────────┐
│   Flutter Client    │◄───►│   Node.js + Express   │
│   (GetX + SQLCipher)│     │   (REST + Socket.IO)  │
└─────────────────────┘     └──────────┬────────────┘
                                       │
                            ┌──────────┼────────────┐
                            │          │            │
                       PostgreSQL    Redis      AWS S3
                       (multi-tenant) (pub/sub)  (SSE-KMS)
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile/Desktop** | Flutter 3.x, GetX (state/routing/DI) |
| **Local Storage** | SQLCipher (encrypted SQLite) |
| **Backend API** | Node.js, Express, TypeScript |
| **Real-time** | Socket.IO with Redis adapter |
| **Database** | PostgreSQL (shared-schema multi-tenant) |
| **Cache/PubSub** | Redis |
| **File Storage** | AWS S3 with SSE-KMS encryption |
| **Push Notifications** | Firebase Cloud Messaging |
| **Auth** | JWT RS256 (15m access / 30d refresh) |

## Features

- One-to-one and group messaging with text, images, audio, and files
- Folder-based chat organization (admin-defined and user-created)
- Typing indicators, read receipts, online presence
- Offline caching with encrypted local database
- Responsive layout — mobile, tablet, and desktop from a single codebase
- RBAC: super_admin, tenant_admin, user roles
- 15-minute inactivity auto-lock
- Append-only audit logging

## Project Structure

```
├── lib/
│   ├── main.dart                    # App entry, DI setup
│   └── chat/
│       ├── app/
│       │   ├── data/
│       │   │   ├── auth/            # JWT session management
│       │   │   ├── client/          # Dio HTTP + Socket.IO clients
│       │   │   ├── local/           # SQLCipher database + DAOs
│       │   │   ├── model/           # Data models
│       │   │   ├── repository/      # Repositories (auth, chat, message, media, folder)
│       │   │   └── service/         # Remote API services (Dio implementations)
│       │   ├── modules/
│       │   │   ├── auth/            # Login screen
│       │   │   ├── chat_detail/     # Chat view (mobile + desktop), message bubble, input bar
│       │   │   ├── chat_list/       # Conversation list with folder tabs
│       │   │   ├── contacts/        # Contact picker
│       │   │   ├── group/           # Create group, group info
│       │   │   ├── media_viewer/    # Image viewer, document viewer
│       │   │   ├── profile/         # User profile
│       │   │   └── settings/        # Settings, notifications, folder management
│       │   ├── routes/              # GetX named routes + bindings
│       │   └── widgets/             # Shared widgets (avatar, badge, gradient button, etc.)
│       └── core/
│           ├── theme/               # Colors, text styles, ChatColors extension
│           └── values/              # Constants, sizes
├── server/
│   └── src/
│       ├── config/                  # Database, Redis, S3, Firebase config
│       ├── controllers/             # Route controllers
│       ├── middleware/              # Auth, RBAC, audit, rate-limit, validation
│       ├── migrations/             # PostgreSQL schema (12 tables)
│       ├── routes/                 # Express route definitions
│       ├── seeds/                  # Default tenant + admin seed
│       ├── services/               # Business logic layer
│       ├── socket/                 # Socket.IO event handlers
│       ├── types/                  # TypeScript interfaces
│       └── utils/                  # Helpers, logger
├── assets/                         # Static assets
├── pubspec.yaml                    # Flutter dependencies
└── SOW_TECHNICAL_SPECIFICATION.md  # Full technical specification
```

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Node.js 18+
- PostgreSQL 15+
- Redis 7+
- AWS account (S3 bucket with SSE-KMS)
- Firebase project (for FCM)

### Server Setup

```bash
cd server
cp .env.example .env
# Edit .env with your database, Redis, AWS, and JWT keys
npm install
npm run migrate
npm run seed
npm run dev
```

**Generate JWT keys:**
```bash
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -pubout -out public.pem
cat private.pem | base64      # Set as JWT_PRIVATE_KEY_BASE64
cat public.pem | base64       # Set as JWT_PUBLIC_KEY_BASE64
```

### Flutter Setup

```bash
flutter pub get
```

Add Firebase config files:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Update the API base URL in the Dio client configuration to point to your server.

```bash
flutter run
```

## Multi-Tenant Architecture

All data is isolated per tenant using a `tenant_id` column on every table. Queries are scoped automatically through middleware. Each tenant gets its own admin who can manage users, folders, and settings.

## HIPAA Compliance

| Control | Implementation |
|---------|---------------|
| Transport encryption | TLS 1.2+ on all connections |
| At-rest encryption (server) | PostgreSQL TDE, S3 SSE-KMS |
| At-rest encryption (client) | SQLCipher encrypted local DB |
| Authentication | JWT RS256, bcrypt passwords, login lockout |
| Session management | 15-min access tokens, 30-day refresh with rotation |
| Inactivity timeout | 15-minute auto-lock |
| Audit logging | Append-only log of all data access and mutations |
| Push notifications | No PHI in notification payloads |
| Access control | Role-based (super_admin / tenant_admin / user) |
| Password policy | Min 8 chars, upper + lower + number + special |

## License

Proprietary. All rights reserved.
