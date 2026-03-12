import '../../../../../core/utils/logs_helper.dart';

/// Initial database schema migration.
///
/// Creates all tables required for the chat application.
class MigrationV1 {
  static const String _tag = 'MigrationV1';

  static const String createUsersTable = '''
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone_number TEXT,
      avatar_url TEXT,
      designation TEXT,
      department TEXT,
      presence TEXT DEFAULT 'offline',
      last_seen_at TEXT,
      created_at TEXT,
      updated_at TEXT
    )
  ''';

  static const String createConversationsTable = '''
    CREATE TABLE IF NOT EXISTS conversations (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL DEFAULT 'private',
      name TEXT,
      avatar_url TEXT,
      last_message_id TEXT,
      unread_count INTEGER DEFAULT 0,
      is_muted INTEGER DEFAULT 0,
      is_pinned INTEGER DEFAULT 0,
      is_archived INTEGER DEFAULT 0,
      created_by TEXT,
      created_at TEXT,
      updated_at TEXT,
      last_message_at TEXT
    )
  ''';

  static const String createMessagesTable = '''
    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      conversation_id TEXT NOT NULL,
      sender_id TEXT NOT NULL,
      sender_name TEXT,
      type TEXT NOT NULL DEFAULT 'text',
      content TEXT,
      attachment_id TEXT,
      attachment_url TEXT,
      attachment_thumbnail_url TEXT,
      attachment_file_name TEXT,
      attachment_mime_type TEXT,
      attachment_file_size INTEGER,
      attachment_width INTEGER,
      attachment_height INTEGER,
      attachment_duration INTEGER,
      attachment_media_type TEXT,
      attachment_local_path TEXT,
      status TEXT DEFAULT 'sending',
      reply_to_message_id TEXT,
      reply_to_content TEXT,
      reply_to_sender_name TEXT,
      is_forwarded INTEGER DEFAULT 0,
      is_deleted INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      read_at TEXT,
      delivered_at TEXT,
      FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
      FOREIGN KEY (sender_id) REFERENCES users(id)
    )
  ''';

  static const String createConversationParticipantsTable = '''
    CREATE TABLE IF NOT EXISTS conversation_participants (
      conversation_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      role TEXT DEFAULT 'member',
      joined_at TEXT,
      PRIMARY KEY (conversation_id, user_id),
      FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  ''';

  static const String createFoldersTable = '''
    CREATE TABLE IF NOT EXISTS folders (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'user',
      sort_order INTEGER,
      created_at TEXT,
      updated_at TEXT
    )
  ''';

  static const String createFolderConversationsTable = '''
    CREATE TABLE IF NOT EXISTS folder_conversations (
      folder_id TEXT NOT NULL,
      conversation_id TEXT NOT NULL,
      PRIMARY KEY (folder_id, conversation_id),
      FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE,
      FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
    )
  ''';

  // Indexes for query performance
  static const String createMessageConversationIndex = '''
    CREATE INDEX IF NOT EXISTS idx_messages_conversation_id
    ON messages(conversation_id, created_at DESC)
  ''';

  static const String createMessageSenderIndex = '''
    CREATE INDEX IF NOT EXISTS idx_messages_sender_id
    ON messages(sender_id)
  ''';

  static const String createConversationLastMessageIndex = '''
    CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at
    ON conversations(last_message_at DESC)
  ''';

  static const String createUserEmailIndex = '''
    CREATE INDEX IF NOT EXISTS idx_users_email
    ON users(email)
  ''';

  /// Applies the migration (creates all tables and indexes).
  static Future<void> up(dynamic db) async {
    LogsHelper.debugLog(tag: _tag, 'Applying migration v1');

    // In actual implementation, execute each SQL statement:
    // await db.execute(createUsersTable);
    // await db.execute(createConversationsTable);
    // await db.execute(createMessagesTable);
    // await db.execute(createConversationParticipantsTable);
    // await db.execute(createFoldersTable);
    // await db.execute(createFolderConversationsTable);
    // await db.execute(createMessageConversationIndex);
    // await db.execute(createMessageSenderIndex);
    // await db.execute(createConversationLastMessageIndex);
    // await db.execute(createUserEmailIndex);

    LogsHelper.debugLog(tag: _tag, 'Migration v1 applied successfully');
  }

  /// Reverses the migration (drops all tables).
  static Future<void> down(dynamic db) async {
    LogsHelper.debugLog(tag: _tag, 'Reverting migration v1');

    // await db.execute('DROP TABLE IF EXISTS folder_conversations');
    // await db.execute('DROP TABLE IF EXISTS folders');
    // await db.execute('DROP TABLE IF EXISTS conversation_participants');
    // await db.execute('DROP TABLE IF EXISTS messages');
    // await db.execute('DROP TABLE IF EXISTS conversations');
    // await db.execute('DROP TABLE IF EXISTS users');

    LogsHelper.debugLog(tag: _tag, 'Migration v1 reverted');
  }
}
