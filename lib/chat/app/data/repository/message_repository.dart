import '../../../core/data/api_response_model.dart';
import '../../../core/utils/logs_helper.dart';
import '../local/database/dao/message_dao.dart';
import '../local/database/dao/pending_message_dao.dart';
import '../model/message_model.dart';
import '../service/message/message_remote_service.dart';

class MessageRepository {
  static const String _tag = 'MessageRepository';

  final MessageRemoteService _messageService;
  final MessageDao _messageDao;
  final PendingMessageDao _pendingMessageDao;

  MessageRepository({
    required MessageRemoteService messageService,
    required MessageDao messageDao,
    required PendingMessageDao pendingMessageDao,
  })  : _messageService = messageService,
        _messageDao = messageDao,
        _pendingMessageDao = pendingMessageDao;

  // ── Local-first reads ─────────────────────────────────────────────────

  /// Returns cached messages from local DB for a conversation.
  Future<List<MessageModel>> getCachedMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return _messageDao.getMessages(
      conversationId,
      limit: limit,
      offset: offset,
    );
  }

  /// Persists messages to local DB cache.
  Future<void> cacheMessages(List<MessageModel> messages) async {
    if (messages.isEmpty) return;
    await _messageDao.insertMessages(messages);
  }

  /// Persists a single message to local DB cache.
  Future<void> cacheMessage(MessageModel message) async {
    await _messageDao.insertMessage(message);
  }

  // ── Offline message queue ─────────────────────────────────────────────

  /// Queues a message for sending (persists to pending_messages table).
  Future<void> queueMessage({
    required String localId,
    required String conversationId,
    required String senderId,
    String? senderName,
    required String type,
    String? content,
    String? mediaId,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
  }) async {
    await _pendingMessageDao.insertPendingMessage({
      'local_id': localId,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'type': type,
      'content': content,
      'media_id': mediaId,
      'reply_to_id': replyToId,
      'reply_to_content': replyToContent,
      'reply_to_sender_name': replyToSenderName,
      'status': 'queued',
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Gets all pending (queued/failed) messages for a conversation.
  Future<List<Map<String, dynamic>>> getPendingMessages(
      String conversationId) async {
    return _pendingMessageDao.getPendingMessagesByConversation(conversationId);
  }

  /// Marks a pending message as sent and moves it to the messages table.
  Future<void> markPendingAsSent(
    String localId,
    String serverId,
    MessageModel confirmedMessage,
  ) async {
    await _pendingMessageDao.deletePendingMessage(localId);
    await _messageDao.insertMessage(confirmedMessage);
  }

  /// Marks a pending message as failed.
  Future<void> markPendingAsFailed(String localId) async {
    await _pendingMessageDao.updateStatus(localId, 'failed');
    await _pendingMessageDao.incrementRetryCount(localId);
  }

  /// Removes a pending message from the queue.
  Future<void> removePendingMessage(String localId) async {
    await _pendingMessageDao.deletePendingMessage(localId);
  }

  // ── Remote operations ─────────────────────────────────────────────────

  Future<ApiResponseModel> getMessages({
    required String conversationId,
    int limit = 50,
    String? cursor,
    String direction = 'forward',
  }) {
    return _messageService.getMessages(
      conversationId: conversationId,
      limit: limit,
      cursor: cursor,
      direction: direction,
    );
  }

  Future<ApiResponseModel> sendMessage({
    required String conversationId,
    required String content,
    required String type,
    String? replyToId,
    String? mediaId,
  }) {
    return _messageService.sendMessage(
      conversationId: conversationId,
      content: content,
      type: type,
      replyToId: replyToId,
      mediaId: mediaId,
    );
  }

  Future<ApiResponseModel> deleteMessage({
    required String conversationId,
    required String messageId,
    bool deleteForEveryone = false,
  }) {
    if (deleteForEveryone) {
      _messageDao.markAsDeleted(messageId);
    }
    return _messageService.deleteMessage(
      conversationId: conversationId,
      messageId: messageId,
      deleteForEveryone: deleteForEveryone,
    );
  }

  Future<ApiResponseModel> markAsRead(String conversationId) {
    return _messageService.markAsRead(conversationId);
  }

  Future<ApiResponseModel> markAsDelivered(String conversationId) {
    return _messageService.markAsDelivered(conversationId);
  }

  Future<ApiResponseModel> getMessageReaders({
    required String conversationId,
    required String messageId,
  }) {
    return _messageService.getMessageReaders(
      conversationId: conversationId,
      messageId: messageId,
    );
  }

  Future<ApiResponseModel> searchMessages({
    required String conversationId,
    required String query,
    int limit = 20,
  }) {
    return _messageService.searchMessages(
      conversationId: conversationId,
      query: query,
      limit: limit,
    );
  }

  Future<ApiResponseModel> getMessagesAround({
    required String conversationId,
    required String messageId,
    int limit = 50,
  }) {
    return _messageService.getMessagesAround(
      conversationId: conversationId,
      messageId: messageId,
      limit: limit,
    );
  }
}
