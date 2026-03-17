import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/utils/logs_helper.dart';
import '../../local/database/dao/conversation_dao.dart';
import '../../local/database/dao/message_dao.dart';
import '../../local/database/dao/pending_message_dao.dart';
import '../../model/message_model.dart';
import '../connectivity/connectivity_service.dart';
import '../socket/socket_service.dart';

/// Synchronisation service that bridges offline-queued messages with the
/// real-time socket layer.
///
/// Responsibilities:
/// 1. Flush pending messages when connectivity is restored.
/// 2. Handle `message:sent` acks to clean up the pending queue.
/// 3. Persist incoming messages from the socket to the local database.
class MessageSyncService extends GetxService {
  static const String _tag = 'MessageSyncService';
  static const int _maxRetries = 3;

  final ConnectivityService _connectivityService;
  final SocketService _socketService;
  final MessageDao _messageDao;
  final PendingMessageDao _pendingMessageDao;
  final ConversationDao _conversationDao;

  final List<StreamSubscription> _subscriptions = [];

  MessageSyncService(
    this._connectivityService,
    this._socketService,
    this._messageDao,
    this._pendingMessageDao,
    this._conversationDao,
  );

  /// Initialises all sync listeners.
  Future<MessageSyncService> init() async {
    _listenToConnectivityChanges();
    _listenToMessageSentAcks();
    _listenToNewMessages();

    LogsHelper.debugLog(tag: _tag, 'Message sync service initialized');
    return this;
  }

  // ── Connectivity: offline -> online ────────────────────────────────────

  void _listenToConnectivityChanges() {
    _subscriptions.add(
      _connectivityService.onConnectivityChanged.listen((isOnline) {
        if (isOnline) {
          LogsHelper.debugLog(
            tag: _tag,
            'Connectivity restored — flushing pending messages',
          );
          _flushPendingMessages();
        }
      }),
    );
  }

  /// Sends all retryable pending messages sequentially.
  Future<void> _flushPendingMessages() async {
    try {
      final pendingMessages = await _pendingMessageDao.getRetryableMessages(
        maxRetries: _maxRetries,
      );

      if (pendingMessages.isEmpty) {
        LogsHelper.debugLog(tag: _tag, 'No pending messages to flush');
        return;
      }

      LogsHelper.debugLog(
        tag: _tag,
        'Flushing ${pendingMessages.length} pending message(s)',
      );

      for (final pending in pendingMessages) {
        final localId = pending['local_id'] as String;
        final conversationId = pending['conversation_id'] as String;
        final type = pending['type'] as String? ?? 'text';
        final content = pending['content'] as String?;
        final mediaId = pending['media_id'] as String?;
        final replyToId = pending['reply_to_id'] as String?;

        // Mark as sending
        await _pendingMessageDao.updateStatus(localId, 'sending');

        // Increment retry count
        await _pendingMessageDao.incrementRetryCount(localId);

        // Send via socket
        _socketService.sendMessage(
          conversationId: conversationId,
          type: type,
          localId: localId,
          content: content,
          mediaId: mediaId,
          replyToId: replyToId,
        );

        LogsHelper.debugLog(
          tag: _tag,
          'Sent pending message: $localId',
        );
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error flushing pending messages: $e');
    }
  }

  // ── message:sent ack ──────────────────────────────────────────────────

  void _listenToMessageSentAcks() {
    _subscriptions.add(
      _socketService.onMessageSent.listen((data) {
        _handleMessageSentAck(data);
      }),
    );
  }

  /// Handles the server acknowledgement for a sent message.
  ///
  /// Server sends: `{ localId, messageId, createdAt }`
  Future<void> _handleMessageSentAck(Map<String, dynamic> data) async {
    try {
      final localId = data['localId'] as String?;
      final messageId = data['messageId'] as String?;

      if (localId == null || messageId == null) {
        LogsHelper.debugLog(
          tag: _tag,
          'Invalid message:sent ack data: $data',
        );
        return;
      }

      // Remove from pending queue
      await _pendingMessageDao.deletePendingMessage(localId);

      LogsHelper.debugLog(
        tag: _tag,
        'Message ack received — localId: $localId, serverId: $messageId',
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error handling message:sent ack: $e');
    }
  }

  // ── Incoming messages ─────────────────────────────────────────────────

  void _listenToNewMessages() {
    _subscriptions.add(
      _socketService.onNewMessage.listen((message) {
        _handleNewMessage(message);
      }),
    );
  }

  /// Persists an incoming message to the local database.
  Future<void> _handleNewMessage(MessageModel message) async {
    try {
      await _messageDao.insertMessage(message);

      // Update conversation's unread count
      await _conversationDao.incrementUnreadCount(message.conversationId);

      LogsHelper.debugLog(
        tag: _tag,
        'Persisted incoming message: ${message.id} '
            'in conversation: ${message.conversationId}',
      );
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error persisting new message: $e');
    }
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.onClose();
  }
}
