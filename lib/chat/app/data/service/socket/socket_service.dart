import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/utils/logs_helper.dart';
import '../../../../core/values/constants/socket_events.dart';
import '../../../data/model/message_model.dart';
import '../../client/socket_client.dart';

/// High-level socket service that translates raw socket events
/// into typed streams for the application to consume.
///
/// Event mapping (server event → stream):
///   message:new          → onNewMessage
///   message:sent         → onMessageSent  (localId → serverId confirmation)
///   message:delivered:ack → onMessageDelivered
///   message:read:ack     → onMessageRead
///   typing:indicator     → onTyping
///   presence:update      → onPresenceUpdate
class SocketService extends GetxService {
  static const String _tag = 'SocketService';

  final SocketClient _socketClient;

  final _newMessageController = StreamController<MessageModel>.broadcast();
  final _messageSentController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeliveredController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _unreadUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<MessageModel> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onMessageSent => _messageSentController.stream;
  Stream<Map<String, dynamic>> get onMessageDelivered => _messageDeliveredController.stream;
  Stream<Map<String, dynamic>> get onMessageRead => _messageReadController.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onPresenceUpdate => _presenceController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated => _conversationUpdatedController.stream;
  Stream<Map<String, dynamic>> get onUnreadUpdate => _unreadUpdateController.stream;

  bool _isInitialized = false;

  SocketService(this._socketClient);

  /// Initializes the socket service and sets up event listeners.
  /// Safe to call multiple times — only the first call has effect.
  Future<SocketService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _setupListeners();
    await _socketClient.connect();
    LogsHelper.debugLog(tag: _tag, 'Socket service initialized');
    return this;
  }

  void _setupListeners() {
    // ── Incoming messages ─────────────────────────────────────────────
    // Server emits 'message:new' to conversation room (excluding sender)
    // Data: { id, conversationId, senderId, senderName, type, content, mediaId, replyToId, createdAt }
    _socketClient.on(SocketEvents.messageNew, (data) {
      try {
        final message = MessageModel.fromJson(data as Map<String, dynamic>);
        _newMessageController.add(message);
      } catch (e) {
        LogsHelper.debugLog(tag: _tag, 'Error parsing new message: $e');
      }
    });

    // Server emits 'message:sent' to sender after processing socket message
    // Data: { localId, messageId, createdAt }
    _socketClient.on(SocketEvents.messageSent, (data) {
      _messageSentController.add(data as Map<String, dynamic>);
    });

    // Server emits 'message:deleted' with { messageId, conversationId, forEveryone }
    _socketClient.on(SocketEvents.messageDeleted, (data) {
      _messageDeletedController.add(data as Map<String, dynamic>);
    });

    // ── Read receipts ─────────────────────────────────────────────────
    // Server emits 'message:delivered:ack' with { messageId, userId, timestamp }
    _socketClient.on(SocketEvents.messageDeliveredAck, (data) {
      _messageDeliveredController.add(data as Map<String, dynamic>);
    });

    // Server emits 'message:read:ack' with { messageId, userId, timestamp }
    _socketClient.on(SocketEvents.messageReadAck, (data) {
      _messageReadController.add(data as Map<String, dynamic>);
    });

    // ── Typing ────────────────────────────────────────────────────────
    // Server emits single 'typing:indicator' event with { conversationId, userId, userName, isTyping }
    _socketClient.on(SocketEvents.typingIndicator, (data) {
      _typingController.add(data as Map<String, dynamic>);
    });

    // ── Presence ──────────────────────────────────────────────────────
    // Server emits 'presence:update' with { userId, status, lastSeenAt }
    _socketClient.on(SocketEvents.presenceUpdate, (data) {
      _presenceController.add(data as Map<String, dynamic>);
    });

    // ── Unread count updates ─────────────────────────────────────────
    // Server emits 'conversation:unread:update' back to the reader after
    // marking messages as read, with { conversationId, unreadCount }
    _socketClient.on(SocketEvents.conversationUnreadUpdate, (data) {
      _unreadUpdateController.add(data as Map<String, dynamic>);
    });
  }

  // ── Outgoing events ───────────────────────────────────────────────────

  /// Sends a message via socket for real-time delivery.
  ///
  /// Server expects 'message:send' with:
  ///   { conversationId, type, content?, mediaId?, replyToId?, localId }
  /// and a callback: (response) => { success, messageId?, error? }
  void sendMessage({
    required String conversationId,
    required String type,
    required String localId,
    String? content,
    String? mediaId,
    String? replyToId,
  }) {
    _socketClient.emitWithAck(
      SocketEvents.sendMessage,
      {
        'conversationId': conversationId,
        'type': type,
        'localId': localId,
        if (content != null) 'content': content,
        if (mediaId != null) 'mediaId': mediaId,
        if (replyToId != null) 'replyToId': replyToId,
      },
      (response) {
        LogsHelper.debugLog(
          tag: _tag,
          'message:send ack: $response',
        );
      },
    );
  }

  /// Deletes a message via socket.
  ///
  /// Server expects 'message:delete' with:
  ///   { conversationId, messageId, forEveryone }
  void deleteMessage({
    required String conversationId,
    required String messageId,
    bool forEveryone = false,
  }) {
    _socketClient.emit(SocketEvents.deleteMessage, {
      'conversationId': conversationId,
      'messageId': messageId,
      'forEveryone': forEveryone,
    });
  }

  /// Joins a conversation room to receive real-time updates.
  void joinConversation(String conversationId) {
    _socketClient.joinConversation(conversationId);
  }

  /// Joins multiple conversation rooms at once.
  void joinConversations(List<String> conversationIds) {
    _socketClient.joinConversations(conversationIds);
  }

  /// Leaves a conversation room.
  void leaveConversation(String conversationId) {
    // Server doesn't define a leave event — rooms are left on disconnect.
    LogsHelper.debugLog(tag: _tag, 'Leave conversation: $conversationId');
  }

  /// Sends a typing indicator for a conversation.
  void startTyping(String conversationId) {
    _socketClient.sendTypingIndicator(conversationId);
  }

  /// Sends a stop typing indicator for a conversation.
  void stopTyping(String conversationId) {
    _socketClient.sendStopTypingIndicator(conversationId);
  }

  /// Marks a message as read via socket.
  /// Server expects 'message:read' with { messageId, conversationId }.
  void markAsRead(String conversationId, String messageId) {
    _socketClient.emit(SocketEvents.messageRead, {
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  /// Queries the current presence of specific user IDs from the server.
  /// Returns a map of userId → status string ('online'/'offline').
  void queryPresence(List<String> userIds, Function(Map<String, String>) callback) {
    _socketClient.emitWithAck('presence:query', {'userIds': userIds}, (response) {
      if (response is Map) {
        final result = <String, String>{};
        response.forEach((key, value) {
          if (value is Map) {
            result[key.toString()] = (value['status'] as String?) ?? 'offline';
          }
        });
        callback(result);
      } else {
        callback({});
      }
    });
  }

  /// Marks a message as delivered via socket.
  /// Server expects 'message:delivered' with { messageId, conversationId }.
  void markAsDelivered(String conversationId, String messageId) {
    _socketClient.emit(SocketEvents.messageDelivered, {
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  /// Disconnects the socket service.
  void disconnect() {
    _socketClient.disconnect();
  }

  @override
  void onClose() {
    _newMessageController.close();
    _messageSentController.close();
    _messageDeliveredController.close();
    _messageReadController.close();
    _messageDeletedController.close();
    _typingController.close();
    _presenceController.close();
    _conversationUpdatedController.close();
    _unreadUpdateController.close();
    disconnect();
    super.onClose();
  }
}
