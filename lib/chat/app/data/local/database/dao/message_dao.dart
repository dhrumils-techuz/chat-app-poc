import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../../core/utils/logs_helper.dart';
import '../../../model/message_model.dart';
import '../../../model/media_attachment_model.dart';
import '../../../types/message_type.dart';
import '../../../types/message_status_type.dart';
import '../app_database.dart';

/// Data Access Object for message-related database operations.
class MessageDao {
  static const String _tag = 'MessageDao';
  static const String _table = 'messages';
  final AppDatabase _appDatabase;

  MessageDao(this._appDatabase);

  /// Inserts a message into the database.
  Future<void> insertMessage(MessageModel message) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      final map = _messageToMap(message);
      await db.insert(_table, map, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Insert message error: $e');
    }
  }

  /// Inserts multiple messages in a batch.
  Future<void> insertMessages(List<MessageModel> messages) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final message in messages) {
          batch.insert(_table, _messageToMap(message),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Batch insert messages error: $e');
    }
  }

  /// Gets messages for a conversation with pagination.
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = _appDatabase.database;
    if (db == null) return [];

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _table,
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );
      return maps.map((map) => _mapToMessage(map)).toList();
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Get messages error: $e');
      return [];
    }
  }

  /// Gets a single message by ID.
  Future<MessageModel?> getMessageById(String messageId) async {
    final db = _appDatabase.database;
    if (db == null) return null;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: [messageId],
        limit: 1,
      );
      if (maps.isNotEmpty) return _mapToMessage(maps.first);
      return null;
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Get message by id error: $e');
      return null;
    }
  }

  /// Updates message status.
  Future<void> updateMessageStatus(
    String messageId,
    MessageStatusType status,
  ) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.update(
        _table,
        {'status': status.value, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Update message status error: $e');
    }
  }

  /// Marks a message as deleted.
  Future<void> markAsDeleted(String messageId) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.update(
        _table,
        {
          'is_deleted': 1,
          'content': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Mark as deleted error: $e');
    }
  }

  /// Removes a single message from the local cache (for delete-for-me).
  Future<void> removeMessage(String messageId) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.delete(_table, where: 'id = ?', whereArgs: [messageId]);
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Remove message error: $e');
    }
  }

  /// Deletes all messages for a conversation.
  Future<void> deleteMessagesForConversation(String conversationId) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.delete(
        _table,
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Delete messages error: $e');
    }
  }

  /// Searches messages by content.
  Future<List<MessageModel>> searchMessages(
    String query, {
    String? conversationId,
    int limit = 50,
  }) async {
    final db = _appDatabase.database;
    if (db == null) return [];

    try {
      String where = 'content LIKE ? AND is_deleted = 0';
      List<dynamic> whereArgs = ['%$query%'];
      if (conversationId != null) {
        where += ' AND conversation_id = ?';
        whereArgs.add(conversationId);
      }
      final maps = await db.query(
        _table,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return maps.map((map) => _mapToMessage(map)).toList();
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Search messages error: $e');
      return [];
    }
  }

  Map<String, dynamic> _messageToMap(MessageModel message) {
    return {
      'id': message.id,
      'conversation_id': message.conversationId,
      'sender_id': message.senderId,
      'sender_name': message.senderName,
      'type': message.type.value,
      'content': message.content,
      'attachment_id': message.attachment?.id,
      'attachment_url': message.attachment?.url,
      'attachment_thumbnail_url': message.attachment?.thumbnailUrl,
      'attachment_file_name': message.attachment?.fileName,
      'attachment_mime_type': message.attachment?.mimeType,
      'attachment_file_size': message.attachment?.fileSize,
      'attachment_width': message.attachment?.width,
      'attachment_height': message.attachment?.height,
      'attachment_duration': message.attachment?.durationInSeconds,
      'attachment_media_type': message.attachment?.mediaType.value,
      'attachment_local_path': message.attachment?.localPath,
      'status': message.status.value,
      'reply_to_message_id': message.replyToMessageId,
      'reply_to_content': message.replyToContent,
      'reply_to_sender_name': message.replyToSenderName,
      'is_forwarded': message.isForwarded ? 1 : 0,
      'is_deleted': message.isDeleted ? 1 : 0,
      'created_at': message.createdAt.toIso8601String(),
      'updated_at': message.updatedAt?.toIso8601String(),
      'read_at': message.readAt?.toIso8601String(),
      'delivered_at': message.deliveredAt?.toIso8601String(),
    };
  }

  MessageModel _mapToMessage(Map<String, dynamic> map) {
    MediaAttachmentModel? attachment;
    if (map['attachment_id'] != null) {
      attachment = MediaAttachmentModel(
        id: map['attachment_id'] as String,
        url: map['attachment_url'] as String,
        thumbnailUrl: map['attachment_thumbnail_url'] as String?,
        fileName: map['attachment_file_name'] as String,
        mimeType: map['attachment_mime_type'] as String?,
        fileSize: map['attachment_file_size'] as int?,
        width: map['attachment_width'] as int?,
        height: map['attachment_height'] as int?,
        durationInSeconds: map['attachment_duration'] as int?,
        mediaType:
            MessageType.fromValue(map['attachment_media_type'] as String),
        localPath: map['attachment_local_path'] as String?,
      );
    }

    return MessageModel(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      senderName: map['sender_name'] as String?,
      type: MessageType.fromValue(map['type'] as String),
      content: map['content'] as String?,
      attachment: attachment,
      status: MessageStatusType.fromValue(map['status'] as String),
      replyToMessageId: map['reply_to_message_id'] as String?,
      replyToContent: map['reply_to_content'] as String?,
      replyToSenderName: map['reply_to_sender_name'] as String?,
      isForwarded: (map['is_forwarded'] as int?) == 1,
      isDeleted: (map['is_deleted'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String)
          : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.parse(map['delivered_at'] as String)
          : null,
    );
  }
}
