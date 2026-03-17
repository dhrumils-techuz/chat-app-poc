import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../../core/utils/logs_helper.dart';
import '../../../model/conversation_model.dart';
import '../../../types/conversation_type.dart';
import '../app_database.dart';

/// Data Access Object for conversation-related database operations.
class ConversationDao {
  static const String _tag = 'ConversationDao';
  static const String _table = 'conversations';
  final AppDatabase _appDatabase;

  ConversationDao(this._appDatabase);

  /// Inserts or updates a conversation.
  Future<void> upsertConversation(ConversationModel conversation) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      final map = _conversationToMap(conversation);
      await db.insert(_table, map, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Upsert conversation error: $e');
    }
  }

  /// Inserts or updates multiple conversations in a batch.
  Future<void> upsertConversations(List<ConversationModel> conversations) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final conversation in conversations) {
          batch.insert(_table, _conversationToMap(conversation),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Batch upsert conversations error: $e');
    }
  }

  /// Gets all conversations ordered by last message time.
  Future<List<ConversationModel>> getConversations({
    int limit = 20,
    int offset = 0,
    bool includeArchived = false,
  }) async {
    final db = _appDatabase.database;
    if (db == null) return [];

    try {
      String where = includeArchived ? '' : 'is_archived = 0';
      final maps = await db.query(
        _table,
        where: where.isNotEmpty ? where : null,
        orderBy: 'is_pinned DESC, last_message_at DESC',
        limit: limit,
        offset: offset,
      );
      return maps.map((map) => _mapToConversation(map)).toList();
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Get conversations error: $e');
      return [];
    }
  }

  /// Gets a single conversation by ID.
  Future<ConversationModel?> getConversationById(String conversationId) async {
    final db = _appDatabase.database;
    if (db == null) return null;

    try {
      final maps = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: [conversationId],
        limit: 1,
      );
      if (maps.isNotEmpty) return _mapToConversation(maps.first);
      return null;
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Get conversation by id error: $e');
      return null;
    }
  }

  /// Updates the unread count for a conversation.
  Future<void> updateUnreadCount(String conversationId, int count) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.update(
        _table,
        {'unread_count': count},
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Update unread count error: $e');
    }
  }

  /// Resets the unread count for a conversation.
  Future<void> resetUnreadCount(String conversationId) async {
    await updateUnreadCount(conversationId, 0);
  }

  /// Increments the unread count by 1.
  Future<void> incrementUnreadCount(String conversationId) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.rawUpdate(
        'UPDATE $_table SET unread_count = unread_count + 1 WHERE id = ?',
        [conversationId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Increment unread count error: $e');
    }
  }

  /// Updates pin status for a conversation.
  Future<void> updatePinStatus(String conversationId, bool isPinned) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.update(
        _table,
        {'is_pinned': isPinned ? 1 : 0},
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Update pin status error: $e');
    }
  }

  /// Updates mute status for a conversation.
  Future<void> updateMuteStatus(String conversationId, bool isMuted) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.update(
        _table,
        {'is_muted': isMuted ? 1 : 0},
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Update mute status error: $e');
    }
  }

  /// Deletes a conversation and its associated messages.
  Future<void> deleteConversation(String conversationId) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.delete(
        _table,
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Delete conversation error: $e');
    }
  }

  /// Searches conversations by name.
  Future<List<ConversationModel>> searchConversations(String query) async {
    final db = _appDatabase.database;
    if (db == null) return [];

    try {
      final maps = await db.query(
        _table,
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'last_message_at DESC',
      );
      return maps.map((map) => _mapToConversation(map)).toList();
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Search conversations error: $e');
      return [];
    }
  }

  Map<String, dynamic> _conversationToMap(ConversationModel conversation) {
    return {
      'id': conversation.id,
      'type': conversation.type.value,
      'name': conversation.name,
      'avatar_url': conversation.avatarUrl,
      'unread_count': conversation.unreadCount,
      'is_muted': conversation.isMuted ? 1 : 0,
      'is_pinned': conversation.isPinned ? 1 : 0,
      'is_archived': conversation.isArchived ? 1 : 0,
      'created_by': conversation.createdBy,
      'created_at': conversation.createdAt?.toIso8601String(),
      'updated_at': conversation.updatedAt?.toIso8601String(),
      'last_message_at': conversation.lastMessageAt?.toIso8601String(),
    };
  }

  ConversationModel _mapToConversation(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] as String,
      type: ConversationType.fromValue(map['type'] as String),
      name: map['name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      unreadCount: map['unread_count'] as int? ?? 0,
      isMuted: (map['is_muted'] as int?) == 1,
      isPinned: (map['is_pinned'] as int?) == 1,
      isArchived: (map['is_archived'] as int?) == 1,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
    );
  }
}
