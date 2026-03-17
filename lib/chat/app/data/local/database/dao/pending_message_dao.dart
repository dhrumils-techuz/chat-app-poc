import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../../core/utils/logs_helper.dart';
import '../app_database.dart';

/// Data Access Object for pending (outgoing, not yet delivered) messages.
///
/// Pending messages are queued locally and sent when connectivity is available.
class PendingMessageDao {
  static const String _tag = 'PendingMessageDao';
  static const String _table = 'pending_messages';
  final AppDatabase _appDatabase;

  PendingMessageDao(this._appDatabase);

  /// Inserts a pending message into the queue.
  Future<void> insertPendingMessage(Map<String, dynamic> data) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.insert(_table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Insert pending message error: $e');
    }
  }

  /// Gets all retryable messages (queued or failed with retry count below max).
  Future<List<Map<String, dynamic>>> getRetryableMessages({
    int maxRetries = 3,
  }) async {
    final db = _appDatabase.database;
    if (db == null) return [];

    try {
      return await db.query(
        _table,
        where:
            "(status = 'queued' OR (status = 'failed' AND retry_count < ?))",
        whereArgs: [maxRetries],
        orderBy: 'created_at ASC',
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Get retryable messages error: $e');
      return [];
    }
  }

  /// Gets all pending messages (queued or failed), ordered by creation time.
  ///
  /// Optionally filter by [conversationId].
  Future<List<Map<String, dynamic>>> getPendingMessages({
    String? conversationId,
  }) async {
    final db = _appDatabase.database;
    if (db == null) return [];

    try {
      String? where;
      List<dynamic>? whereArgs;

      if (conversationId != null) {
        where = 'conversation_id = ? AND (status = ? OR status = ?)';
        whereArgs = [conversationId, 'queued', 'failed'];
      } else {
        where = 'status = ? OR status = ?';
        whereArgs = ['queued', 'failed'];
      }

      return await db.query(
        _table,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at ASC',
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Get pending messages error: $e');
      return [];
    }
  }

  /// Gets pending messages for a specific conversation.
  Future<List<Map<String, dynamic>>> getPendingMessagesByConversation(
    String conversationId,
  ) async {
    return getPendingMessages(conversationId: conversationId);
  }

  /// Updates the status of a pending message.
  Future<void> updateStatus(String localId, String status) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.update(
        _table,
        {'status': status},
        where: 'local_id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Update pending message status error: $e');
    }
  }

  /// Increments the retry count for a pending message.
  Future<void> incrementRetryCount(String localId) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.rawUpdate(
        'UPDATE $_table SET retry_count = retry_count + 1 WHERE local_id = ?',
        [localId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Increment retry count error: $e');
    }
  }

  /// Deletes a pending message (e.g., after successful send).
  Future<void> deletePendingMessage(String localId) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.delete(
        _table,
        where: 'local_id = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Delete pending message error: $e');
    }
  }

  /// Deletes all pending messages (e.g., on logout).
  Future<void> deleteAllPending() async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.delete(_table);
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Delete all pending messages error: $e');
    }
  }
}
