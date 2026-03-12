import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/utils/logs_helper.dart';
import '../../../../core/values/constants/socket_events.dart';
import '../../../data/model/message_model.dart';
import '../../client/socket_client.dart';

/// High-level socket service that translates raw socket events
/// into typed streams for the application to consume.
class SocketService extends GetxService {
  static const String _tag = 'SocketService';

  final SocketClient _socketClient;

  final _newMessageController = StreamController<MessageModel>.broadcast();
  final _messageDeliveredController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedController = StreamController<String>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<MessageModel> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onMessageDelivered => _messageDeliveredController.stream;
  Stream<Map<String, dynamic>> get onMessageRead => _messageReadController.stream;
  Stream<String> get onMessageDeleted => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onPresenceUpdate => _presenceController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated => _conversationUpdatedController.stream;

  SocketService(this._socketClient);

  /// Initializes the socket service and sets up event listeners.
  Future<SocketService> init() async {
    _setupListeners();
    await _socketClient.connect();
    LogsHelper.debugLog(tag: _tag, 'Socket service initialized');
    return this;
  }

  void _setupListeners() {
    _socketClient.on(SocketEvents.newMessage, (data) {
      try {
        final message = MessageModel.fromJson(data as Map<String, dynamic>);
        _newMessageController.add(message);
      } catch (e) {
        LogsHelper.debugLog(tag: _tag, 'Error parsing new message: $e');
      }
    });

    _socketClient.on(SocketEvents.messageDelivered, (data) {
      _messageDeliveredController.add(data as Map<String, dynamic>);
    });

    _socketClient.on(SocketEvents.messageRead, (data) {
      _messageReadController.add(data as Map<String, dynamic>);
    });

    _socketClient.on(SocketEvents.messageDeleted, (data) {
      final messageId = data is Map ? data['messageId'] as String : data as String;
      _messageDeletedController.add(messageId);
    });

    _socketClient.on(SocketEvents.userTyping, (data) {
      _typingController.add(data as Map<String, dynamic>);
    });

    _socketClient.on(SocketEvents.userStoppedTyping, (data) {
      _typingController.add({
        ...data as Map<String, dynamic>,
        'isTyping': false,
      });
    });

    _socketClient.on(SocketEvents.presenceUpdate, (data) {
      _presenceController.add(data as Map<String, dynamic>);
    });

    _socketClient.on(SocketEvents.userOnline, (data) {
      _presenceController.add({
        ...data as Map<String, dynamic>,
        'status': 'online',
      });
    });

    _socketClient.on(SocketEvents.userOffline, (data) {
      _presenceController.add({
        ...data as Map<String, dynamic>,
        'status': 'offline',
      });
    });

    _socketClient.on(SocketEvents.conversationUpdated, (data) {
      _conversationUpdatedController.add(data as Map<String, dynamic>);
    });

    _socketClient.on(SocketEvents.conversationCreated, (data) {
      _conversationUpdatedController.add({
        ...data as Map<String, dynamic>,
        'action': 'created',
      });
    });
  }

  /// Sends a message via socket for real-time delivery.
  void sendMessage(Map<String, dynamic> messageData) {
    _socketClient.emit(SocketEvents.sendMessage, messageData);
  }

  /// Joins a conversation room to receive real-time updates.
  void joinConversation(String conversationId) {
    _socketClient.joinConversation(conversationId);
  }

  /// Leaves a conversation room.
  void leaveConversation(String conversationId) {
    _socketClient.leaveConversation(conversationId);
  }

  /// Sends a typing indicator for a conversation.
  void startTyping(String conversationId) {
    _socketClient.sendTypingIndicator(conversationId);
  }

  /// Sends a stop typing indicator for a conversation.
  void stopTyping(String conversationId) {
    _socketClient.sendStopTypingIndicator(conversationId);
  }

  /// Sends a mark-as-read event.
  void markAsRead(String conversationId, String messageId) {
    _socketClient.emit(SocketEvents.markRead, {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  /// Sends a mark-as-delivered event.
  void markAsDelivered(String conversationId, String messageId) {
    _socketClient.emit(SocketEvents.markDelivered, {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  /// Disconnects the socket service.
  void disconnect() {
    _socketClient.disconnect();
  }

  @override
  void onClose() {
    _newMessageController.close();
    _messageDeliveredController.close();
    _messageReadController.close();
    _messageDeletedController.close();
    _typingController.close();
    _presenceController.close();
    _conversationUpdatedController.close();
    disconnect();
    super.onClose();
  }
}
