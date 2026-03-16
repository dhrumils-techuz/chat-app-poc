# MedChat — HIPAA-Compliant Medical Chat Application

A WhatsApp-style secure messaging platform built for medical sales representatives. Enables HIPAA-compliant one-to-one and group messaging across Android, iOS, Web, and Desktop from a single Flutter codebase, backed by a Node.js real-time server.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Minimum System Requirements](#minimum-system-requirements)
- [Project Structure](#project-structure)
- [Setup Guide](#setup-guide)
  - [Step 1 — Install Prerequisites](#step-1--install-prerequisites)
  - [Step 2 — PostgreSQL Setup](#step-2--postgresql-setup)
  - [Step 3 — Redis Setup](#step-3--redis-setup)
  - [Step 4 — Generate JWT RS256 Keys](#step-4--generate-jwt-rs256-keys)
  - [Step 5 — Server Environment Configuration](#step-5--server-environment-configuration)
  - [Step 6 — Install and Run the Server](#step-6--install-and-run-the-server)
  - [Step 7 — Firebase Setup (Optional)](#step-7--firebase-setup-optional)
  - [Step 8 — Flutter Client Setup](#step-8--flutter-client-setup)
  - [Step 9 — Run the Flutter App](#step-9--run-the-flutter-app)
  - [Step 10 — First Login](#step-10--first-login)
- [Environment Variables Reference](#environment-variables-reference)
- [Test Credentials](#test-credentials)
- [API Endpoints Reference](#api-endpoints-reference)
- [API Detailed Documentation](#api-detailed-documentation)
- [Socket Events Reference](#socket-events-reference)
- [Database Schema](#database-schema)
- [App Routes (Flutter)](#app-routes-flutter)
- [Design System](#design-system)
- [Multi-Tenant Architecture](#multi-tenant-architecture)
- [HIPAA Compliance](#hipaa-compliance)
- [File Upload Limits](#file-upload-limits)
- [Server Commands Reference](#server-commands-reference)
- [Deployment](#deployment)
  - [Server Deployment](#server-deployment)
  - [Flutter App Deployment](#flutter-app-deployment)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        Client Layer                              │
│  ┌────────────┐  ┌────────────┐  ┌─────────┐  ┌─────────────┐  │
│  │  Android    │  │    iOS     │  │   Web   │  │   Desktop   │  │
│  │  (Flutter)  │  │  (Flutter) │  │(Flutter)│  │  (Flutter)  │  │
│  └─────┬──────┘  └─────┬──────┘  └────┬────┘  └──────┬──────┘  │
│        └────────────────┴──────────────┴──────────────┘          │
│                              │                                   │
│               GetX (State / Routing / DI)                        │
│               SQLCipher (Encrypted Local DB)                     │
│               Dio (HTTP) + Socket.IO (Real-time)                 │
└──────────────────────────────┬───────────────────────────────────┘
                               │ TLS 1.2+
┌──────────────────────────────┴───────────────────────────────────┐
│                        Server Layer                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │              Node.js + Express + TypeScript               │    │
│  │         REST API (CRUD) + Socket.IO (Real-time)          │    │
│  │    JWT RS256 Auth │ RBAC │ Rate Limit │ Audit Logging    │    │
│  └──────┬───────────────────┬─────────────────┬─────────────┘    │
│         │                   │                 │                   │
│  ┌──────┴──────┐    ┌──────┴──────┐   ┌──────┴──────┐           │
│  │ PostgreSQL  │    │    Redis    │   │   AWS S3    │           │
│  │ (Data Store │    │  (PubSub,  │   │  (SSE-KMS   │           │
│  │  Multi-     │    │  Sessions, │   │  Encrypted  │           │
│  │  Tenant)    │    │  Presence) │   │  Media)     │           │
│  └─────────────┘    └────────────┘   └─────────────┘           │
│                                                                  │
│         Firebase Cloud Messaging (Push Notifications)            │
└──────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer                     | Technology                     | Purpose                                       |
| ------------------------- | ------------------------------ | --------------------------------------------- |
| **Mobile/Desktop Client** | Flutter 3.x, Dart ^3.6.1       | Cross-platform UI                             |
| **State Management**      | GetX 4.x                       | Reactive state, routing, dependency injection |
| **Local Storage**         | SQLCipher (sqflite_sqlcipher)  | AES-256 encrypted offline database            |
| **HTTP Client**           | Dio 5.x                        | REST API calls with interceptors              |
| **Real-time**             | Socket.IO Client 3.x           | WebSocket messaging, typing, presence         |
| **Backend Runtime**       | Node.js 20+, Express 4.x       | REST API server                               |
| **Backend Language**      | TypeScript 5.x (ES2022 target) | Type-safe server code                         |
| **Real-time Server**      | Socket.IO 4.x + Redis Adapter  | Scalable WebSocket with pub/sub               |
| **Database**              | PostgreSQL 15+                 | Relational data, multi-tenant                 |
| **Cache / PubSub**        | Redis 7+                       | Session cache, socket scaling, presence       |
| **File Storage**          | AWS S3 with SSE-KMS            | HIPAA-compliant encrypted media storage       |
| **Push Notifications**    | Firebase Cloud Messaging       | Background notifications (no PHI)             |
| **Authentication**        | JWT RS256                      | Asymmetric token signing                      |
| **Password Hashing**      | bcryptjs                       | Salted password storage                       |
| **Validation**            | Zod                            | Runtime request schema validation             |
| **Logging**               | Winston                        | Structured server logging                     |

---

## Features

### Messaging

- One-to-one direct messaging
- Group conversations with admin/member roles
- Text, image, audio, and document messages
- Reply-to-message threading
- Message deletion (for me / for everyone)
- Optimistic message sending with temp IDs
- Cursor-based pagination for message history

### Real-time

- Typing indicators (animated dots with user names)
- Online/offline presence tracking
- Read receipts and delivery confirmations
- Real-time conversation updates

### Organization

- Folder-based chat grouping (admin-defined org-wide + user-created personal)
- Conversation search
- Unread message badges

### Responsive UI

- Adaptive layout: single-panel (mobile) ↔ split-panel (tablet/desktop)
- Breakpoint at 600px width
- Platform-specific fonts: Roboto (Android/Windows), SourceSansPro (iOS)
- WhatsApp-style message bubbles with green sent / grey received

### Security & Compliance

- HIPAA-compliant transport (TLS) and at-rest encryption
- JWT RS256 with 15-min access tokens and 30-day rotating refresh tokens
- Role-based access control (super_admin / tenant_admin / user)
- 15-minute inactivity auto-lock
- Append-only audit logging
- No PHI in push notification payloads
- Password complexity enforcement (8+ chars, upper + lower + number + special)
- Login attempt lockout
- Screenshot prevention (configurable)

### Offline Support

- SQLCipher encrypted local database
- Offline message caching
- Automatic sync on reconnection

---

## Minimum System Requirements

### Development Machine

| Requirement        | Minimum                               | Recommended                |
| ------------------ | ------------------------------------- | -------------------------- |
| **OS**             | macOS 12+, Windows 10+, Ubuntu 20.04+ | macOS 14+ (for iOS builds) |
| **RAM**            | 8 GB                                  | 16 GB                      |
| **Disk**           | 10 GB free                            | 20 GB free                 |
| **Flutter SDK**    | 3.22+ (Dart SDK ^3.6.1)               | Latest stable              |
| **Node.js**        | 20.0.0                                | 20 LTS                     |
| **Java JDK**       | 11 (for Android builds)               | 17                         |
| **Xcode**          | 15+ (macOS only, for iOS builds)      | Latest                     |
| **Android Studio** | Hedgehog+                             | Latest                     |
| **PostgreSQL**     | 15                                    | 16                         |
| **Redis**          | 7.0                                   | 7.2+                       |

### Target Platforms

| Platform    | Minimum Target                                 |
| ----------- | ---------------------------------------------- |
| **Android** | API 21 (Android 5.0) — set by Flutter defaults |
| **iOS**     | iOS 12.0                                       |
| **Web**     | Chrome 88+, Safari 14+, Firefox 85+, Edge 88+  |
| **macOS**   | macOS 10.14+                                   |
| **Windows** | Windows 10+                                    |
| **Linux**   | Ubuntu 20.04+                                  |

### Server (Production)

| Resource       | Minimum                              | Recommended          |
| -------------- | ------------------------------------ | -------------------- |
| **CPU**        | 2 vCPUs                              | 4 vCPUs              |
| **RAM**        | 2 GB                                 | 4 GB                 |
| **Disk**       | 20 GB SSD                            | 50 GB SSD            |
| **PostgreSQL** | 1 GB RAM, 10 GB disk                 | 2 GB RAM, 50 GB disk |
| **Redis**      | 512 MB RAM                           | 1 GB RAM             |
| **Network**    | 100 Mbps                             | 1 Gbps               |
| **OS**         | Ubuntu 22.04 LTS / Amazon Linux 2023 | Same                 |

---

## Project Structure

```
medchat/
├── lib/                                  # Flutter application source
│   ├── main.dart                         # Entry point, Firebase init, DI setup
│   └── chat/
│       ├── app/
│       │   ├── data/
│       │   │   ├── auth/
│       │   │   │   └── jwt_auth_service.dart        # Session management, token refresh
│       │   │   ├── client/
│       │   │   │   ├── dio_remote_api_client.dart   # Dio HTTP client with interceptors
│       │   │   │   └── socket_client.dart           # Socket.IO connection manager
│       │   │   ├── local/
│       │   │   │   └── database/
│       │   │   │       ├── app_database.dart         # SQLCipher database initialization
│       │   │   │       ├── dao/
│       │   │   │       │   ├── conversation_dao.dart # Local conversation queries
│       │   │   │       │   ├── message_dao.dart      # Local message queries
│       │   │   │       │   └── user_dao.dart         # Local user queries
│       │   │   │       └── migrations/
│       │   │   │           └── migration_v1.dart     # Local DB schema
│       │   │   ├── model/
│       │   │   │   ├── conversation_model.dart       # Conversation with displayName, hasUnread
│       │   │   │   ├── message_model.dart            # Message with all types
│       │   │   │   ├── user_model.dart               # User with presence, initials
│       │   │   │   ├── chat_folder_model.dart        # Folder model
│       │   │   │   ├── device_model.dart             # Device registration
│       │   │   │   ├── group_member_model.dart       # Group membership
│       │   │   │   ├── login_response_model.dart     # Auth response
│       │   │   │   ├── media_attachment_model.dart   # Media metadata
│       │   │   │   └── message_status_model.dart     # Read/delivery status
│       │   │   ├── repository/
│       │   │   │   ├── auth_repository.dart          # Login, logout, refresh
│       │   │   │   ├── chat_repository.dart          # Conversations CRUD + search
│       │   │   │   ├── message_repository.dart       # Messages CRUD
│       │   │   │   ├── media_repository.dart         # Upload/download media
│       │   │   │   ├── folder_repository.dart        # Folder CRUD
│       │   │   │   └── token_repository.dart         # Secure token storage
│       │   │   └── service/
│       │   │       ├── auth/                         # Auth API (abstract + Dio impl)
│       │   │       ├── chat/                         # Chat API (abstract + Dio impl)
│       │   │       ├── message/                      # Message API (abstract + Dio impl)
│       │   │       ├── media/                        # Media API (abstract + Dio impl)
│       │   │       └── socket/
│       │   │           └── socket_service.dart       # Stream-based socket event manager
│       │   ├── modules/
│       │   │   ├── auth/
│       │   │   │   ├── sign_in_screen.dart
│       │   │   │   └── sign_in_controller.dart
│       │   │   ├── chat_list/
│       │   │   │   ├── chat_list_screen.dart         # Responsive: mobile or desktop
│       │   │   │   ├── chat_list_controller.dart     # Conversation list state
│       │   │   │   └── widget/
│       │   │   │       ├── chat_list_view_mobile.dart
│       │   │   │       ├── chat_list_view_desktop.dart
│       │   │   │       ├── conversation_tile.dart
│       │   │   │       └── folder_tab_bar.dart
│       │   │   ├── chat_detail/
│       │   │   │   ├── chat_detail_screen.dart       # Responsive: mobile or desktop
│       │   │   │   ├── chat_detail_controller.dart   # Message list, send, reply, delete
│       │   │   │   └── widget/
│       │   │   │       ├── chat_detail_view_mobile.dart   # Scaffold + AppBar
│       │   │   │       ├── chat_detail_view_desktop.dart  # Embedded panel (no Scaffold)
│       │   │   │       ├── message_bubble.dart             # WhatsApp-style bubbles
│       │   │   │       ├── message_input_bar.dart          # Text input + attachments
│       │   │   │       ├── typing_indicator_widget.dart    # Animated typing dots
│       │   │   │       ├── media_preview_widget.dart       # Image/audio/doc preview
│       │   │   │       └── audio_player_widget.dart        # Inline audio player
│       │   │   ├── contacts/
│       │   │   │   ├── contacts_screen.dart
│       │   │   │   ├── contacts_controller.dart
│       │   │   │   └── widget/contact_tile.dart
│       │   │   ├── group/
│       │   │   │   ├── create_group_screen.dart
│       │   │   │   ├── create_group_controller.dart
│       │   │   │   ├── group_info_screen.dart
│       │   │   │   ├── group_info_controller.dart
│       │   │   │   └── widget/                       # Group member tiles, etc.
│       │   │   ├── media_viewer/
│       │   │   │   ├── image_viewer_screen.dart       # Full-screen image with zoom
│       │   │   │   └── document_viewer_screen.dart    # Document info + download
│       │   │   ├── profile/
│       │   │   │   ├── profile_screen.dart
│       │   │   │   └── profile_controller.dart
│       │   │   └── settings/
│       │   │       ├── settings_screen.dart
│       │   │       ├── settings_controller.dart
│       │   │       └── widget/
│       │   │           ├── notification_settings.dart  # Notification toggle switches
│       │   │           └── folder_management.dart      # CRUD for personal folders
│       │   ├── routes/
│       │   │   ├── app_routes.dart                    # Route name constants
│       │   │   └── app_pages.dart                     # Route → Screen + Binding map
│       │   └── widgets/                               # Shared reusable widgets
│       │       ├── avatar_widget.dart
│       │       ├── online_indicator.dart
│       │       ├── badge_count_widget.dart
│       │       ├── empty_state_widget.dart
│       │       ├── gradient_button.dart
│       │       └── adaptive_layout.dart               # Split-panel responsive layout
│       └── core/
│           ├── theme/
│           │   ├── color.dart                         # AppColor + ChatColors extension
│           │   └── text_style.dart                    # ChatTextStyles (platform-aware)
│           ├── values/
│           │   ├── app_sizes.dart                     # Spacing & sizing constants
│           │   └── constants/
│           │       └── socket_events.dart             # Socket event name constants
│           └── env/
│               └── env.dart                           # Environment URL configuration
│
├── server/                               # Node.js backend
│   ├── package.json
│   ├── tsconfig.json                     # ES2022, strict, path aliases
│   ├── .env.example                      # Environment template
│   └── src/
│       ├── index.ts                      # Server entry point
│       ├── app.ts                        # Express app setup
│       ├── config/
│       │   ├── database.ts               # PostgreSQL pool config
│       │   ├── redis.ts                  # Redis connection
│       │   ├── s3.ts                     # AWS S3 client + upload limits
│       │   ├── firebase.ts              # FCM initialization
│       │   └── env.ts                    # Environment variable validation
│       ├── middleware/
│       │   ├── auth.ts                   # JWT verification middleware
│       │   ├── rbac.ts                   # Role-based access control
│       │   ├── audit.ts                  # Append-only audit logger
│       │   ├── rate-limit.ts             # Request rate limiting
│       │   ├── validation.ts             # Zod schema validation
│       │   └── tenant.ts                # Tenant isolation middleware
│       ├── routes/
│       │   ├── auth.ts                   # /api/auth/*
│       │   ├── users.ts                  # /api/users/*
│       │   ├── conversations.ts          # /api/conversations/*
│       │   ├── messages.ts               # /api/messages/*
│       │   ├── media.ts                  # /api/media/*
│       │   ├── folders.ts                # /api/folders/*
│       │   ├── admin.ts                  # /api/admin/*
│       │   └── health.ts                # /api/health/*
│       ├── controllers/                  # Request handlers
│       ├── services/                     # Business logic
│       ├── socket/                       # Socket.IO event handlers
│       ├── migrations/
│       │   ├── run.ts                    # Migration runner
│       │   ├── 001_initial_schema.sql    # Core tables (11)
│       │   └── 003_audit_tables.sql      # Audit log table
│       ├── seeds/
│       │   └── seed-admin.ts             # Default tenant + super admin
│       ├── types/                        # TypeScript interfaces
│       └── utils/                        # Helpers, logger
│
├── android/                              # Android platform files
├── ios/                                  # iOS platform files
├── web/                                  # Web platform files (PWA-enabled)
├── macos/                                # macOS platform files
├── windows/                              # Windows platform files
├── linux/                                # Linux platform files
├── assets/
│   ├── fonts/                            # Montserrat, Roboto font files
│   ├── images/                           # App images and icons
│   └── .env.chat                         # Flutter environment config
├── pubspec.yaml                          # Flutter dependencies
├── analysis_options.yaml                 # Dart lint rules
├── SOW_TECHNICAL_SPECIFICATION.md        # Full technical specification document
└── .gitignore
```

---

## Setup Guide

### Step 1 — Install Prerequisites

**macOS (Homebrew):**

```bash
# Flutter (if not already installed)
brew install --cask flutter
flutter doctor

# Node.js 20
brew install node@20

# PostgreSQL
brew install postgresql@15
brew services start postgresql@15

# Redis
brew install redis
brew services start redis
```

**Ubuntu / Debian:**

```bash
# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql

# Redis
sudo apt install -y redis-server
sudo systemctl start redis-server

# Flutter — follow https://docs.flutter.dev/get-started/install/linux
```

**Windows:**

```powershell
# Using Chocolatey
choco install nodejs --version=20
choco install postgresql15
choco install redis-64

# Flutter — follow https://docs.flutter.dev/get-started/install/windows
```

**Verify installations:**

```bash
flutter --version          # Should show Flutter 3.x, Dart 3.6+
node --version             # Should show v20.x.x
psql --version             # Should show 15.x+
redis-server --version     # Should show 7.x+
```

---

### Step 2 — PostgreSQL Setup

```bash
# Create the database user and database
psql postgres <<EOF
CREATE USER medical_chat_user WITH PASSWORD 'changeme_in_production';
CREATE DATABASE medical_chat OWNER medical_chat_user;
GRANT ALL PRIVILEGES ON DATABASE medical_chat TO medical_chat_user;
\c medical_chat
GRANT ALL ON SCHEMA public TO medical_chat_user;
EOF
```

**Verify the connection:**

```bash
psql -U medical_chat_user -d medical_chat -h localhost -c "SELECT 1;"
```

> **Note:** On Ubuntu, you may need to edit `pg_hba.conf` to allow password authentication for local connections.

---

### Step 3 — Redis Setup

Redis should be running from Step 1. Verify:

```bash
redis-cli ping
# Should return: PONG
```

By default, Redis runs on `localhost:6379` with no password. For production, always set a password.

---

### Step 4 — Generate JWT RS256 Keys

The server uses RSA-256 asymmetric keys for JWT signing.

```bash
cd server

# Generate 2048-bit RSA private key
openssl genrsa -out private.pem 2048

# Extract public key
openssl rsa -in private.pem -pubout -out public.pem

# Base64 encode for environment variables
# macOS:
echo "JWT_PRIVATE_KEY_BASE64:"
cat private.pem | base64

echo ""
echo "JWT_PUBLIC_KEY_BASE64:"
cat public.pem | base64

# Linux (use -w 0 for single-line output):
# cat private.pem | base64 -w 0
# cat public.pem | base64 -w 0
```

Copy both base64 strings — you will need them in the next step.

> **Important:** Never commit `private.pem` or `public.pem` to version control. They are already in `.gitignore`.

---

### Step 5 — Server Environment Configuration

```bash
cd server
cp .env.example .env
```

Open `server/.env` and configure all values:

```env
# ── Server ────────────────────────────────
NODE_ENV=development
PORT=3000
HOST=0.0.0.0

# ── PostgreSQL ────────────────────────────
DATABASE_URL=postgresql://medical_chat_user:changeme_in_production@localhost:5432/medical_chat
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=20

# ── Redis ─────────────────────────────────
REDIS_URL=redis://localhost:6379

# ── JWT (paste base64 keys from Step 4) ──
JWT_PRIVATE_KEY_BASE64=<paste-private-key-base64>
JWT_PUBLIC_KEY_BASE64=<paste-public-key-base64>
JWT_ACCESS_TOKEN_EXPIRY=15m
JWT_REFRESH_TOKEN_EXPIRY_DAYS=30

# ── AWS S3 (optional for dev) ────────────
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_BUCKET_NAME=medical-chat-media
S3_PRESIGNED_URL_EXPIRY=900

# ── Firebase FCM (optional for dev) ──────
FIREBASE_SERVICE_ACCOUNT_BASE64=

# ── CORS ──────────────────────────────────
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# ── Rate Limiting ─────────────────────────
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# ── Audit ─────────────────────────────────
AUDIT_LOG_RETENTION_DAYS=2555

# ── Encryption (generate: openssl rand -hex 32) ──
ENCRYPTION_KEY=<paste-256-bit-hex-key>
```

**Generate the encryption key:**

```bash
openssl rand -hex 32
```

---

### Step 6 — Install and Run the Server

```bash
cd server

# Install dependencies
npm install

# Run database migrations (creates all 12 tables)
npx ts-node src/migrations/run.ts

# Seed the default tenant and super admin user
npx ts-node src/seeds/seed-admin.ts

# Start the development server (auto-restarts on changes)
npm run dev
```

**Expected output:**

```
[info] Server listening on http://0.0.0.0:3000
[info] PostgreSQL pool connected
[info] Redis connected
[info] Socket.IO ready
```

**Verify the server is healthy:**

```bash
curl http://localhost:3000/api/health
# Should return: { "status": "ok", ... }
```

---

### Step 7 — Firebase Setup (Optional)

Firebase is only required for push notifications. The app works fully without it for development.

1. Go to [Firebase Console](https://console.firebase.google.com) → Create or select a project
2. Enable **Cloud Messaging** in project settings
3. **Android:** Download `google-services.json` → place in `android/app/`
4. **iOS:** Download `GoogleService-Info.plist` → place in `ios/Runner/`
5. **Server FCM:** Go to Project Settings → Service Accounts → Generate new private key → then:
   ```bash
   cat service-account.json | base64
   # Paste result into FIREBASE_SERVICE_ACCOUNT_BASE64 in server/.env
   ```

---

### Step 8 — Flutter Client Setup

```bash
# From the project root
flutter pub get
```

**Configure the API base URL:**

Edit `assets/.env.chat` (or the env config at `lib/chat/core/env/env.dart`):

| Environment          | API URL                           | Socket URL                    |
| -------------------- | --------------------------------- | ----------------------------- |
| **Development**      | `http://localhost:3000/api`       | `http://localhost:3000`       |
| **Android Emulator** | `http://10.0.2.2:3000/api`        | `http://10.0.2.2:3000`        |
| **iOS Simulator**    | `http://localhost:3000/api`       | `http://localhost:3000`       |
| **Physical Device**  | `http://<your-local-ip>:3000/api` | `http://<your-local-ip>:3000` |

> **Tip:** Find your local IP with `ifconfig | grep "inet " | grep -v 127.0.0.1`

**iOS additional setup:**

```bash
cd ios
pod install
cd ..
```

---

### Step 9 — Run the Flutter App

```bash
# List available devices
flutter devices

# Run on a specific target
flutter run                        # Default connected device
flutter run -d chrome              # Web browser
flutter run -d macos               # macOS desktop
flutter run -d <device-id>         # Specific device

# Run in release mode (for performance testing)
flutter run --release
```

---

### Step 10 — First Login

Use the seeded super admin credentials:

| Field        | Value                      |
| ------------ | -------------------------- |
| **Email**    | `admin@medical-chat.local` |
| **Password** | `Admin@1234!`              |

> These defaults can be overridden by setting `SUPER_ADMIN_EMAIL` and `SUPER_ADMIN_PASSWORD` environment variables before running the seed script.

After first login, you can:

1. Create new tenants (organizations) via admin routes
2. Create users within each tenant
3. Start conversations between users in the same tenant

---

## Environment Variables Reference

### Server (`server/.env`)

| Variable                          | Required | Default                 | Description                            |
| --------------------------------- | -------- | ----------------------- | -------------------------------------- |
| `NODE_ENV`                        | No       | `development`           | `development`, `production`, or `test` |
| `PORT`                            | No       | `3000`                  | HTTP server port                       |
| `HOST`                            | No       | `0.0.0.0`               | Bind address                           |
| `DATABASE_URL`                    | **Yes**  | —                       | PostgreSQL connection string           |
| `DATABASE_POOL_MIN`               | No       | `2`                     | Min DB pool connections                |
| `DATABASE_POOL_MAX`               | No       | `20`                    | Max DB pool connections                |
| `REDIS_URL`                       | **Yes**  | —                       | Redis connection string                |
| `JWT_PRIVATE_KEY_BASE64`          | **Yes**  | —                       | Base64-encoded RSA private key         |
| `JWT_PUBLIC_KEY_BASE64`           | **Yes**  | —                       | Base64-encoded RSA public key          |
| `JWT_ACCESS_TOKEN_EXPIRY`         | No       | `15m`                   | Access token TTL                       |
| `JWT_REFRESH_TOKEN_EXPIRY_DAYS`   | No       | `30`                    | Refresh token TTL in days              |
| `AWS_REGION`                      | No       | `us-east-1`             | AWS S3 region                          |
| `AWS_ACCESS_KEY_ID`               | No\*     | —                       | AWS credentials (\*required for media) |
| `AWS_SECRET_ACCESS_KEY`           | No\*     | —                       | AWS credentials (\*required for media) |
| `S3_BUCKET_NAME`                  | No\*     | `medical-chat-media`    | S3 bucket for uploads                  |
| `S3_PRESIGNED_URL_EXPIRY`         | No       | `900`                   | Pre-signed URL TTL (seconds)           |
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | No       | —                       | FCM service account (for push)         |
| `CORS_ALLOWED_ORIGINS`            | No       | `http://localhost:3000` | Comma-separated allowed origins        |
| `RATE_LIMIT_WINDOW_MS`            | No       | `900000`                | Rate limit window (15 min)             |
| `RATE_LIMIT_MAX_REQUESTS`         | No       | `100`                   | Max requests per window                |
| `AUDIT_LOG_RETENTION_DAYS`        | No       | `2555`                  | ~7 years (HIPAA requirement)           |
| `ENCRYPTION_KEY`                  | No       | —                       | 256-bit hex key for PHI encryption     |

### Flutter Client (`assets/.env.chat`)

| Variable      | Description                                                  |
| ------------- | ------------------------------------------------------------ |
| `DEV_URL`     | Development API base URL (e.g., `http://localhost:3000/api`) |
| `STAGING_URL` | Staging API base URL                                         |
| `PROD_URL`    | Production API base URL                                      |

---

## Test Credentials

All test accounts use the password shown below. Use any of these to login via the Flutter app or API.

### Super Admin (System-wide access)

| Email                      | Password      | Role        | Tenant               |
| -------------------------- | ------------- | ----------- | -------------------- |
| `admin@medical-chat.local` | `Admin@1234!` | super_admin | Default Organization |

### Tenant Admins (1 per tenant)

| Email                      | Password     | Role         | Tenant                |
| -------------------------- | ------------ | ------------ | --------------------- |
| `john.admin@acme.com`      | `Test@1234!` | tenant_admin | Acme Pharma           |
| `lisa.admin@medtech.com`   | `Test@1234!` | tenant_admin | MedTech Solutions     |
| `mark.admin@biovista.com`  | `Test@1234!` | tenant_admin | BioVista Health       |
| `diana.admin@novacare.com` | `Test@1234!` | tenant_admin | NovaCare Medical      |
| `peter.admin@pinnacle.com` | `Test@1234!` | tenant_admin | Pinnacle Therapeutics |

### Regular Users (4 per tenant)

| Email                      | Password     | Role | Tenant                |
| -------------------------- | ------------ | ---- | --------------------- |
| `sarah.rep@acme.com`       | `Test@1234!` | user | Acme Pharma           |
| `david.rep@acme.com`       | `Test@1234!` | user | Acme Pharma           |
| `emily.rep@acme.com`       | `Test@1234!` | user | Acme Pharma           |
| `alex.rep@acme.com`        | `Test@1234!` | user | Acme Pharma           |
| `tom.rep@medtech.com`      | `Test@1234!` | user | MedTech Solutions     |
| `nina.rep@medtech.com`     | `Test@1234!` | user | MedTech Solutions     |
| `chris.rep@medtech.com`    | `Test@1234!` | user | MedTech Solutions     |
| `rachel.rep@medtech.com`   | `Test@1234!` | user | MedTech Solutions     |
| `anna.rep@biovista.com`    | `Test@1234!` | user | BioVista Health       |
| `james.rep@biovista.com`   | `Test@1234!` | user | BioVista Health       |
| `olivia.rep@biovista.com`  | `Test@1234!` | user | BioVista Health       |
| `ryan.rep@biovista.com`    | `Test@1234!` | user | BioVista Health       |
| `kevin.rep@novacare.com`   | `Test@1234!` | user | NovaCare Medical      |
| `laura.rep@novacare.com`   | `Test@1234!` | user | NovaCare Medical      |
| `brian.rep@novacare.com`   | `Test@1234!` | user | NovaCare Medical      |
| `megan.rep@novacare.com`   | `Test@1234!` | user | NovaCare Medical      |
| `sophia.rep@pinnacle.com`  | `Test@1234!` | user | Pinnacle Therapeutics |
| `daniel.rep@pinnacle.com`  | `Test@1234!` | user | Pinnacle Therapeutics |
| `jessica.rep@pinnacle.com` | `Test@1234!` | user | Pinnacle Therapeutics |
| `andrew.rep@pinnacle.com`  | `Test@1234!` | user | Pinnacle Therapeutics |

### Role Permissions Summary

| Role           | Can Chat | Manage Users | Manage Tenants | View Audit Logs |
| -------------- | -------- | ------------ | -------------- | --------------- |
| `user`         | Yes      | No           | No             | No              |
| `tenant_admin` | Yes      | Own tenant   | No             | Own tenant      |
| `super_admin`  | Yes      | All tenants  | Yes            | All tenants     |

---

## API Endpoints Reference

### Authentication — `/api/auth`

| Method | Path                    | Description                 | Auth                    |
| ------ | ----------------------- | --------------------------- | ----------------------- |
| `POST` | `/auth/login`           | Login with email + password | No                      |
| `POST` | `/auth/refresh`         | Refresh access token        | No (uses refresh token) |
| `POST` | `/auth/logout`          | Revoke refresh token        | Yes                     |
| `POST` | `/auth/change-password` | Change user password        | Yes                     |

### Users — `/api/users`

| Method | Path            | Description              | Auth  |
| ------ | --------------- | ------------------------ | ----- |
| `GET`  | `/users/me`     | Get current user profile | Yes   |
| `GET`  | `/users/search` | Search users in tenant   | Yes   |
| `GET`  | `/users`        | List all users           | Admin |
| `POST` | `/users`        | Create new user          | Admin |
| `GET`  | `/users/:id`    | Get user by ID           | Yes   |
| `PUT`  | `/users/:id`    | Update user              | Admin |

### Conversations — `/api/conversations`

| Method   | Path                                      | Description             | Auth |
| -------- | ----------------------------------------- | ----------------------- | ---- |
| `POST`   | `/conversations`                          | Create conversation     | Yes  |
| `GET`    | `/conversations`                          | List user conversations | Yes  |
| `GET`    | `/conversations/:id`                      | Get conversation detail | Yes  |
| `PUT`    | `/conversations/:id`                      | Update conversation     | Yes  |
| `POST`   | `/conversations/:id/participants`         | Add participant         | Yes  |
| `DELETE` | `/conversations/:id/participants/:userId` | Remove participant      | Yes  |

### Messages — `/api/messages`

| Method   | Path                                   | Description                     | Auth |
| -------- | -------------------------------------- | ------------------------------- | ---- |
| `POST`   | `/messages/:conversationId`            | Send message                    | Yes  |
| `GET`    | `/messages/:conversationId`            | Get messages (cursor paginated) | Yes  |
| `GET`    | `/messages/:conversationId/:messageId` | Get single message              | Yes  |
| `DELETE` | `/messages/:conversationId/:messageId` | Delete message                  | Yes  |

### Media — `/api/media`

| Method | Path                                  | Description                    | Auth |
| ------ | ------------------------------------- | ------------------------------ | ---- |
| `POST` | `/media/upload-url`                   | Get S3 pre-signed upload URL   | Yes  |
| `POST` | `/media/confirm-upload`               | Confirm upload completed       | Yes  |
| `GET`  | `/media/:id/download-url`             | Get S3 pre-signed download URL | Yes  |
| `GET`  | `/media/conversation/:conversationId` | List conversation media        | Yes  |

### Folders — `/api/folders`

| Method   | Path                                         | Description                  | Auth |
| -------- | -------------------------------------------- | ---------------------------- | ---- |
| `POST`   | `/folders`                                   | Create folder                | Yes  |
| `GET`    | `/folders`                                   | List folders                 | Yes  |
| `PUT`    | `/folders/:id`                               | Update folder                | Yes  |
| `DELETE` | `/folders/:id`                               | Delete folder                | Yes  |
| `POST`   | `/folders/:id/conversations`                 | Add conversation to folder   | Yes  |
| `DELETE` | `/folders/:id/conversations/:conversationId` | Remove from folder           | Yes  |
| `GET`    | `/folders/:id/conversations`                 | List conversations in folder | Yes  |

### Admin — `/api/admin`

| Method | Path                          | Description          | Auth          |
| ------ | ----------------------------- | -------------------- | ------------- |
| `POST` | `/admin/tenants`              | Create tenant        | Super Admin   |
| `GET`  | `/admin/tenants`              | List tenants         | Super Admin   |
| `GET`  | `/admin/tenants/:id`          | Get tenant           | Super Admin   |
| `PUT`  | `/admin/tenants/:id`          | Update tenant        | Super Admin   |
| `GET`  | `/admin/tenants/:id/stats`    | Tenant statistics    | Super Admin   |
| `GET`  | `/admin/audit-logs`           | Tenant audit logs    | Tenant Admin+ |
| `GET`  | `/admin/audit-logs/:tenantId` | Specific tenant logs | Super Admin   |

### Health — `/api/health`

| Method | Path            | Description                  | Auth |
| ------ | --------------- | ---------------------------- | ---- |
| `GET`  | `/health`       | Overall health check         | No   |
| `GET`  | `/health/ready` | Readiness probe (DB + Redis) | No   |
| `GET`  | `/health/live`  | Liveness probe               | No   |

---

## API Detailed Documentation

> **Base URL**: `http://localhost:3000/api`
> **Auth**: Pass `Authorization: Bearer <token>` header for protected endpoints.
> All request/response bodies are JSON. All timestamps are ISO 8601.

### Authentication

#### POST `/api/auth/login`

Login and receive JWT tokens.

```json
// Request
{
  "email": "sarah.rep@acme.com",
  "password": "Test@1234!",
  "deviceId": "optional-uuid",
  "deviceName": "iPhone 15",
  "platform": "ios",
  "fcmToken": "firebase-token"
}

// Response 200
{
  "success": true,
  "data": {
    "tokens": {
      "accessToken": "eyJhbG...",
      "refreshToken": "d746c9...",
      "expiresIn": "15m"
    },
    "user": {
      "id": "uuid",
      "email": "sarah.rep@acme.com",
      "fullName": "Sarah Rep",
      "role": "user",
      "tenantId": "uuid"
    }
  }
}
```

#### POST `/api/auth/refresh`

Rotate tokens using a refresh token.

```json
// Request
{ "refreshToken": "d746c9..." }

// Response 200
{
  "success": true,
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "new-token...",
    "expiresIn": "15m"
  }
}
```

#### POST `/api/auth/logout` (Auth required)

Revokes refresh tokens for the current device.

#### POST `/api/auth/change-password` (Auth required)

```json
// Request
{
  "currentPassword": "Test@1234!",
  "newPassword": "NewPass@5678!"
}
```

### Users

#### GET `/api/users/me` (Auth required)

Returns the authenticated user's profile.

#### GET `/api/users/search?q=sarah&limit=20` (Auth required)

Search users within the same tenant. Returns id, email, fullName, avatarUrl, role.

#### GET `/api/users?search=&role=user&isActive=true&limit=20&offset=0` (tenant_admin+)

List all users in the tenant with pagination.

#### POST `/api/users` (tenant_admin+)

```json
// Request
{
  "email": "newuser@example.com",
  "password": "Secure@1234!",
  "fullName": "New User",
  "phone": "+1234567890",
  "role": "user"
}

// Response 201
{
  "success": true,
  "data": {
    "id": "uuid",
    "tenantId": "uuid",
    "email": "newuser@example.com",
    "fullName": "New User",
    "role": "user",
    "isActive": true,
    "createdAt": "2026-03-13T08:00:00.000Z"
  }
}
```

#### GET `/api/users/:id` (Auth required)

Get a specific user by ID (within same tenant).

#### PUT `/api/users/:id` (Self or tenant_admin+)

```json
// Request (all fields optional)
{
  "fullName": "Updated Name",
  "phone": "+9876543210",
  "avatarUrl": "https://...",
  "isActive": false
}
```

### Conversations

#### POST `/api/conversations` (Auth required)

```json
// Request
{
  "type": "direct",
  "participantIds": ["user-uuid-1", "user-uuid-2"]
}

// For group chat:
{
  "type": "group",
  "name": "Sales Team",
  "participantIds": ["uuid-1", "uuid-2", "uuid-3"]
}
```

#### GET `/api/conversations?limit=20&offset=0` (Auth required)

List conversations for the authenticated user. Returns unreadCount, messageCount, lastMessageAt.

#### GET `/api/conversations/:id` (Auth required)

Get conversation detail with full participant list.

#### PUT `/api/conversations/:id` (Auth required)

```json
{ "name": "Updated Group Name", "avatarUrl": "https://..." }
```

#### POST `/api/conversations/:id/participants` (Auth required)

```json
{ "userId": "user-uuid", "role": "member" }
```

#### DELETE `/api/conversations/:id/participants/:userId` (Auth required)

### Messages

#### POST `/api/messages/:conversationId` (Auth required)

```json
// Text message
{ "type": "text", "content": "Hello!" }

// Media message
{ "type": "image", "mediaId": "media-uuid", "content": "Photo caption" }

// Reply
{ "type": "text", "content": "Reply text", "replyToId": "message-uuid" }
```

#### GET `/api/messages/:conversationId?cursor=&limit=20&direction=forward` (Auth required)

Cursor-based pagination. Returns messages with sender info, nextCursor, prevCursor, hasMore.

#### GET `/api/messages/:conversationId/:messageId` (Auth required)

Get a single message by ID.

#### DELETE `/api/messages/:conversationId/:messageId` (Auth required)

Soft-delete a message (sender or conversation admin only).

### Media

#### POST `/api/media/upload-url` (Auth required, rate limited)

```json
// Request
{
  "conversationId": "conv-uuid",
  "fileName": "photo.jpg",
  "mimeType": "image/jpeg",
  "fileSize": 1048576
}

// Response 200
{
  "success": true,
  "data": {
    "mediaId": "media-uuid",
    "uploadUrl": "https://s3.amazonaws.com/...",
    "s3Key": "tenants/uuid/media/...",
    "expiresIn": 3600
  }
}
```

Upload the file directly to the `uploadUrl` via PUT, then confirm:

#### POST `/api/media/confirm-upload` (Auth required)

```json
{
  "mediaId": "media-uuid",
  "s3Key": "tenants/uuid/media/...",
  "conversationId": "conv-uuid",
  "fileName": "photo.jpg",
  "mimeType": "image/jpeg",
  "fileSize": 1048576
}
```

#### GET `/api/media/:id/download-url` (Auth required)

Returns a presigned S3 download URL (valid for 1 hour).

#### GET `/api/media/conversation/:conversationId?limit=20&offset=0&mimeType=image/jpeg` (Auth required)

List all media in a conversation with optional MIME type filter.

### Folders

#### POST `/api/folders` (Auth required)

```json
{ "name": "Important", "color": "#FF5733" }
```

#### GET `/api/folders` (Auth required)

List all folders for the authenticated user.

#### PUT `/api/folders/:id` (Auth required)

```json
{ "name": "Urgent", "color": "#E43D3D", "sortOrder": 0 }
```

#### DELETE `/api/folders/:id` (Auth required)

#### POST `/api/folders/:id/conversations` (Auth required)

```json
{ "conversationId": "conv-uuid" }
```

#### DELETE `/api/folders/:id/conversations/:conversationId` (Auth required)

#### GET `/api/folders/:id/conversations` (Auth required)

### Admin (Super Admin Only)

#### POST `/api/admin/tenants` (super_admin)

```json
// Request
{
  "name": "New Pharma Co",
  "adminEmail": "admin@newpharma.com",
  "adminPassword": "Secure@1234!",
  "adminFullName": "Admin Name",
  "domain": "newpharma.com",
  "settings": {}
}

// Response 201
{
  "success": true,
  "data": {
    "tenant": {
      "id": "uuid",
      "name": "New Pharma Co",
      "is_active": true,
      "created_at": "2026-03-13T08:00:00.000Z"
    },
    "admin": {
      "id": "uuid",
      "email": "admin@newpharma.com",
      "fullName": "Admin Name",
      "role": "tenant_admin"
    }
  }
}
```

#### GET `/api/admin/tenants?limit=20&offset=0` (super_admin)

List all tenants with user and conversation counts.

#### GET `/api/admin/tenants/:id` (super_admin)

Get tenant detail with stats.

#### PUT `/api/admin/tenants/:id` (super_admin)

Update tenant name, domain, or settings.

#### GET `/api/admin/tenants/:id/stats` (super_admin)

Returns userCount, activeUserCount, conversationCount, messageCount, mediaCount, totalMediaSize.

### Audit Logs

#### GET `/api/admin/audit-logs?userId=&action=LOGIN&resourceType=session&startDate=&endDate=&limit=50&offset=0` (tenant_admin+)

View audit logs for the authenticated user's tenant.

#### GET `/api/admin/audit-logs/:tenantId` (super_admin)

View audit logs for a specific tenant.

### Health Checks (No Auth)

| Endpoint                | Purpose                     |
| ----------------------- | --------------------------- |
| `GET /api/health`       | Overall status (DB + Redis) |
| `GET /api/health/ready` | Readiness probe             |
| `GET /api/health/live`  | Liveness probe              |

### Error Response Format

All errors follow this structure:

```json
{
  "error": "Human-readable error message",
  "code": "MACHINE_READABLE_CODE",
  "requestId": "uuid"
}
```

Common error codes: `VALIDATION_ERROR`, `INVALID_CREDENTIALS`, `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `RATE_LIMIT_EXCEEDED`, `ACCOUNT_LOCKED`, `INTERNAL_ERROR`.

### Quick Start with cURL

```bash
# 1. Login (get token)
curl -s -X POST http://localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d @- <<< '{"email":"sarah.rep@acme.com","password":"Test@1234!"}'

# 2. Use token for authenticated requests
TOKEN="eyJhbG..."

# Get my profile
curl -s http://localhost:3000/api/users/me \
  -H "Authorization: Bearer $TOKEN"

# Search users
curl -s "http://localhost:3000/api/users/search?q=david" \
  -H "Authorization: Bearer $TOKEN"

# Create a direct conversation
curl -s -X POST http://localhost:3000/api/conversations \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"type":"direct","participantIds":["other-user-uuid"]}'

# Send a message
curl -s -X POST http://localhost:3000/api/messages/CONV_UUID \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"type":"text","content":"Hello from cURL!"}'

# List conversations
curl -s "http://localhost:3000/api/conversations?limit=20" \
  -H "Authorization: Bearer $TOKEN"
```

---

## Socket Events Reference

### Client → Server (Emit)

| Event                | Payload                                  | Description                    |
| -------------------- | ---------------------------------------- | ------------------------------ |
| `authenticate`       | `{ token }`                              | Authenticate socket connection |
| `send_message`       | `{ conversationId, content, type, ... }` | Send a message                 |
| `start_typing`       | `{ conversationId }`                     | User started typing            |
| `stop_typing`        | `{ conversationId }`                     | User stopped typing            |
| `join_conversation`  | `{ conversationId }`                     | Join conversation room         |
| `leave_conversation` | `{ conversationId }`                     | Leave conversation room        |
| `mark_read`          | `{ conversationId, messageId }`          | Mark message as read           |
| `mark_delivered`     | `{ conversationId, messageId }`          | Mark as delivered              |

### Server → Client (Listen)

| Event                  | Payload                         | Description                   |
| ---------------------- | ------------------------------- | ----------------------------- |
| `authenticated`        | `{ userId }`                    | Auth successful               |
| `authentication_error` | `{ message }`                   | Auth failed                   |
| `new_message`          | `MessageModel`                  | New message received          |
| `message_delivered`    | `{ messageId, userId }`         | Delivery confirmation         |
| `message_read`         | `{ messageId, userId }`         | Read confirmation             |
| `message_deleted`      | `{ messageId, deletedFor }`     | Message was deleted           |
| `message_updated`      | `MessageModel`                  | Message was edited            |
| `user_typing`          | `{ conversationId, user }`      | Someone is typing             |
| `user_stopped_typing`  | `{ conversationId, userId }`    | Stopped typing                |
| `user_online`          | `{ userId }`                    | User came online              |
| `user_offline`         | `{ userId, lastSeen }`          | User went offline             |
| `presence_update`      | `{ userId, status }`            | Presence changed              |
| `conversation_updated` | `ConversationModel`             | Conversation metadata changed |
| `conversation_created` | `ConversationModel`             | New conversation              |
| `member_added`         | `{ conversationId, user }`      | Member added to group         |
| `member_removed`       | `{ conversationId, userId }`    | Member removed from group     |
| `read_receipt`         | `{ messageId, userId, readAt }` | Read receipt                  |
| `delivery_receipt`     | `{ messageId, userId }`         | Delivery receipt              |
| `error`                | `{ message, code }`             | Error event                   |

---

## Database Schema

12 tables with shared-schema multi-tenant isolation:

| Table                       | Description                     | Key Columns                                                            |
| --------------------------- | ------------------------------- | ---------------------------------------------------------------------- |
| `tenants`                   | Organizations                   | `id`, `name`, `slug`, `settings`                                       |
| `users`                     | All users across tenants        | `id`, `tenant_id`, `email`, `password_hash`, `role`                    |
| `devices`                   | Registered devices (FCM)        | `id`, `user_id`, `fcm_token`, `platform`                               |
| `conversations`             | Chat threads                    | `id`, `tenant_id`, `type` (direct/group), `name`                       |
| `conversation_participants` | Membership                      | `conversation_id`, `user_id`, `role` (owner/admin/member)              |
| `messages`                  | All messages                    | `id`, `conversation_id`, `sender_id`, `content`, `type`, `reply_to_id` |
| `message_status`            | Per-user read/delivery tracking | `message_id`, `user_id`, `status`, `timestamp`                         |
| `media`                     | File metadata                   | `id`, `message_id`, `s3_key`, `mime_type`, `size`                      |
| `chat_folders`              | Chat folders                    | `id`, `tenant_id`, `user_id`, `name`, `type` (admin/user)              |
| `chat_folder_conversations` | Folder membership               | `folder_id`, `conversation_id`                                         |
| `refresh_tokens`            | Active refresh tokens           | `id`, `user_id`, `token_hash`, `device_id`, `expires_at`               |
| `audit_logs`                | Append-only audit trail         | `id`, `tenant_id`, `user_id`, `action`, `resource`, `details`          |

> The `audit_logs` table has database-level protections preventing UPDATE and DELETE operations.

---

## App Routes (Flutter)

| Route           | Screen              | Description                      |
| --------------- | ------------------- | -------------------------------- |
| `/sign-in`      | `SignInScreen`      | Email + password login           |
| `/chat-list`    | `ChatListScreen`    | Conversation list (home screen)  |
| `/chat-detail`  | `ChatDetailScreen`  | Message thread view              |
| `/contacts`     | `ContactsScreen`    | User search / contact picker     |
| `/new-group`    | `CreateGroupScreen` | Create new group conversation    |
| `/group-info`   | `GroupInfoScreen`   | Group details, members, settings |
| `/profile`      | `ProfileScreen`     | Current user profile             |
| `/settings`     | `SettingsScreen`    | App settings + logout            |
| `/media-viewer` | `ImageViewerScreen` | Full-screen image viewer         |

---

## Design System

### Colors

| Token             | Hex       | Usage                          |
| ----------------- | --------- | ------------------------------ |
| `primary`         | `#10C17D` | Primary actions, links, badges |
| `primaryLight`    | `#01F094` | Gradient end color             |
| `sentBubble`      | `#E7FFED` | Outgoing message background    |
| `receivedBubble`  | `#F2F4F7` | Incoming message background    |
| `black`           | `#09101D` | Primary text                   |
| `grey3`           | `#545D69` | Secondary text                 |
| `grey5`           | `#858C94` | Placeholder text               |
| `divider`         | `#DADEE3` | Borders and dividers           |
| `error`           | `#E43D3D` | Error states                   |
| `onlineGreen`     | `#4CAF50` | Online presence indicator      |
| `backgroundGrey`  | `#F7F8FA` | Page backgrounds               |
| `inputBackground` | `#F2F4F7` | Input field backgrounds        |

### Typography

Platform-aware font selection:

- **Android / Windows:** Roboto
- **iOS / macOS:** SourceSansPro (with Roboto fallback if not bundled)

| Style        | Size | Weight         | Usage                          |
| ------------ | ---- | -------------- | ------------------------------ |
| `title`      | 26px | Bold (700)     | Page titles                    |
| `heading`    | 18px | SemiBold (600) | Section headers, contact names |
| `body`       | 16px | Regular (400)  | Message text, body copy        |
| `bodyMedium` | 16px | Medium (500)   | Emphasized body text           |
| `caption`    | 14px | Regular (400)  | Timestamps, metadata           |
| `small`      | 12px | Regular (400)  | Badges, minor labels           |

### Responsive Breakpoints

| Width     | Layout  | Description                                           |
| --------- | ------- | ----------------------------------------------------- |
| `< 600px` | Mobile  | Single panel, full-screen navigation                  |
| `≥ 600px` | Desktop | Split panel — conversation list (350px) + chat detail |

---

## Multi-Tenant Architecture

All data is scoped by `tenant_id`, enforced at:

1. **Database level:** Every query includes `WHERE tenant_id = ?`
2. **Middleware level:** Tenant ID extracted from JWT and injected into request context
3. **Socket level:** Users can only join conversation rooms within their tenant

**Roles:**

| Role           | Scope         | Capabilities                                  |
| -------------- | ------------- | --------------------------------------------- |
| `super_admin`  | Global        | Manage tenants, view cross-tenant audit logs  |
| `tenant_admin` | Single tenant | Manage users, folders, view tenant audit logs |
| `user`         | Single tenant | Chat, create personal folders                 |

---

## HIPAA Compliance

| Control                         | Implementation                                       | Status |
| ------------------------------- | ---------------------------------------------------- | ------ |
| **Transport encryption**        | TLS 1.2+ enforced on all connections                 | ✅     |
| **At-rest encryption (server)** | PostgreSQL TDE, S3 SSE-KMS (AES-256)                 | ✅     |
| **At-rest encryption (client)** | SQLCipher encrypted local database                   | ✅     |
| **Authentication**              | JWT RS256, bcrypt password hashing                   | ✅     |
| **Session management**          | 15-min access tokens, 30-day rotating refresh tokens | ✅     |
| **Inactivity timeout**          | 15-minute auto-lock on client                        | ✅     |
| **Audit logging**               | Append-only, ~7-year retention (2555 days)           | ✅     |
| **Push notifications**          | No PHI in notification payloads                      | ✅     |
| **Access control**              | RBAC (super_admin / tenant_admin / user)             | ✅     |
| **Password policy**             | Min 8 chars, upper + lower + number + special        | ✅     |
| **Login lockout**               | Account lockout after repeated failed attempts       | ✅     |
| **Multi-tenant isolation**      | tenant_id scoping on all queries + socket rooms      | ✅     |
| **Media security**              | Time-limited pre-signed S3 URLs (15 min)             | ✅     |

> **Note:** This implementation provides HIPAA technical safeguards. Full HIPAA compliance also requires administrative safeguards (BAAs, training, incident response plans) that are outside the scope of this software.

---

## File Upload Limits

| File Type     | Max Size | Allowed MIME Types                   |
| ------------- | -------- | ------------------------------------ |
| **Images**    | 16 MB    | JPEG, PNG, WebP                      |
| **Audio**     | 25 MB    | AAC, M4A, MP3                        |
| **Documents** | 100 MB   | PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX |

All uploads use S3 pre-signed URLs — files go directly from client to S3, never through the server.

---

## Server Commands Reference

| Command                               | Description                                    |
| ------------------------------------- | ---------------------------------------------- |
| `npm run dev`                         | Start dev server with hot-reload (ts-node-dev) |
| `npm run build`                       | Compile TypeScript → `dist/`                   |
| `npm start`                           | Run compiled production build from `dist/`     |
| `npm run typecheck`                   | Type-check without emitting files              |
| `npm run lint`                        | Run ESLint on server source                    |
| `npx ts-node src/migrations/run.ts`   | Run database migrations                        |
| `npx ts-node src/seeds/seed-admin.ts` | Seed default tenant + admin                    |

---

## Deployment

### Server Deployment

#### Option A: Docker (Recommended)

Create a `Dockerfile` in `server/`:

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

```bash
docker build -t medchat-server .
docker run -p 3000:3000 --env-file .env medchat-server
```

#### Option B: AWS EC2 / VPS

```bash
# On the server
git clone <repo-url>
cd server
npm ci --production
npm run build
npm run migrate
npm run seed

# Use PM2 for process management
npm install -g pm2
pm2 start dist/index.js --name medchat-server
pm2 save
pm2 startup
```

#### Option C: AWS ECS / EKS

1. Push Docker image to ECR
2. Create ECS task definition with environment variables
3. Create ECS service with ALB (Application Load Balancer)
4. Enable sticky sessions for Socket.IO on ALB
5. Use RDS for PostgreSQL, ElastiCache for Redis

#### Production Checklist

- [ ] Set `NODE_ENV=production`
- [ ] Use strong, unique passwords for PostgreSQL and Redis
- [ ] Configure TLS/SSL termination on load balancer
- [ ] Set up S3 bucket with SSE-KMS and proper IAM policies
- [ ] Enable PostgreSQL TDE (Transparent Data Encryption)
- [ ] Set Redis `requirepass` and enable TLS
- [ ] Configure CORS to only allow your domain(s)
- [ ] Set up log aggregation (CloudWatch / ELK)
- [ ] Configure auto-scaling based on WebSocket connection count
- [ ] Set up database backups (automated daily + point-in-time recovery)
- [ ] Create IAM roles with least-privilege access
- [ ] Enable VPC and security groups to restrict network access
- [ ] Sign BAA with AWS for HIPAA compliance

### Flutter App Deployment

#### Android (Play Store)

```bash
# Generate release keystore (one time)
keytool -genkey -v -keystore release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias medchat

# Build release APK
flutter build apk --release

# Build release App Bundle (recommended for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

#### iOS (App Store)

```bash
# Build release IPA
flutter build ipa --release

# Output: build/ios/ipa/MedChat.ipa
# Open Xcode → Archive → Upload to App Store Connect
```

#### Web

```bash
flutter build web --release

# Output: build/web/
# Deploy to any static host (S3 + CloudFront, Vercel, Netlify, Firebase Hosting)
```

#### macOS

```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/MedChat.app
```

#### Windows

```bash
flutter build windows --release
# Output: build/windows/x64/runner/Release/
```

---

## Troubleshooting

### Server Issues

| Problem                              | Cause                       | Solution                                                                 |
| ------------------------------------ | --------------------------- | ------------------------------------------------------------------------ |
| `ECONNREFUSED` on PostgreSQL         | PostgreSQL not running      | `brew services start postgresql@15` or `sudo systemctl start postgresql` |
| `ECONNREFUSED` on Redis              | Redis not running           | `brew services start redis` or `sudo systemctl start redis-server`       |
| `JWT_PRIVATE_KEY_BASE64 is required` | Missing `.env` values       | Complete Step 4 and Step 5                                               |
| `relation "users" does not exist`    | Migrations not run          | `npx ts-node src/migrations/run.ts`                                      |
| `password authentication failed`     | Wrong DB credentials        | Check `DATABASE_URL` in `.env` matches Step 2                            |
| Port 3000 already in use             | Another process on port     | `lsof -i :3000` to find it, or change `PORT` in `.env`                   |
| Socket.IO connection drops           | Redis adapter not connected | Verify Redis is running and `REDIS_URL` is correct                       |

### Flutter Issues

| Problem                                   | Cause                     | Solution                                                     |
| ----------------------------------------- | ------------------------- | ------------------------------------------------------------ |
| `SocketException: Connection refused`     | Wrong API URL             | Use `10.0.2.2` for Android emulator, `localhost` for iOS sim |
| `sqflite_sqlcipher` build error (iOS)     | Missing pods              | `cd ios && pod install && cd ..`                             |
| `sqflite_sqlcipher` build error (Android) | NDK issue                 | Ensure Android NDK is installed via Android Studio           |
| Firebase initialization failed            | Missing config files      | Add `google-services.json` / `GoogleService-Info.plist`      |
| `flutter pub get` fails                   | Dart SDK version mismatch | Ensure Flutter 3.22+ with Dart ^3.6.1                        |
| White screen on web                       | CORS error                | Add `http://localhost:<port>` to `CORS_ALLOWED_ORIGINS`      |
| Fonts not rendering                       | Missing font files        | Check `assets/fonts/` has Roboto and SourceSansPro TTFs      |
| GetX binding error                        | Missing DI registration   | Check `main.dart` registers all services before navigation   |

### General

| Problem                        | Cause                    | Solution                                                           |
| ------------------------------ | ------------------------ | ------------------------------------------------------------------ |
| Can't log in                   | Admin not seeded         | Run `npx ts-node src/seeds/seed-admin.ts`                          |
| Messages not real-time         | Socket not authenticated | Check JWT token is passed on socket `authenticate` event           |
| Media upload fails             | AWS not configured       | Set `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `S3_BUCKET_NAME` |
| Push notifications not working | Firebase not set up      | Complete Step 7 (optional — app works without it)                  |

---

## Contributing

1. Create a feature branch from `main`
2. Follow existing code patterns (GetX controllers, Dio services, repository pattern)
3. Run `flutter analyze` before submitting
4. Run `npm run typecheck` for server changes
5. All new API endpoints must include audit logging middleware
6. All new database queries must include `tenant_id` scoping

---

## License

Proprietary. All rights reserved.
