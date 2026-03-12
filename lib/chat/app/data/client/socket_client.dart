import 'dart:async';

import 'package:get/get.dart';

import '../../../core/env/env.dart';
import '../../../core/utils/logs_helper.dart';
import '../../../core/values/constants/app_constants.dart';
import '../../../core/values/constants/socket_events.dart';
import '../repository/token_repository.dart';

/// Socket.IO wrapper service that manages the WebSocket connection.
///
/// This service handles connection, reconnection, authentication,
/// and provides a clean API for emitting and listening to events.
///
/// Note: Requires the socket_io_client package to be added to pubspec.yaml:
///   socket_io_client: ^2.0.3+1
class SocketClient extends GetxService {
  static const String _tag = 'SocketClient';

  final TokenRepository _tokenRepository;

  dynamic _socket;
  final _isConnected = false.obs;
  final _isAuthenticated = false.obs;

  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  final Map<String, List<Function(dynamic)>> _eventListeners = {};

  bool get isConnected => _isConnected.value;
  bool get isAuthenticated => _isAuthenticated.value;

  SocketClient(this._tokenRepository);

  /// Initializes the socket connection with authentication.
  Future<void> connect() async {
    final accessToken = await _tokenRepository.getAccessToken();
    if (accessToken == null) {
      LogsHelper.debugLog(tag: _tag, 'No access token available for socket connection');
      return;
    }

    try {
      // The actual socket_io_client initialization would be:
      // _socket = IO.io(Env.socketUrl, OptionBuilder()
      //     .setTransports(['websocket'])
      //     .setAuth({'token': accessToken})
      //     .enableAutoConnect()
      //     .enableReconnection()
      //     .setReconnectionAttempts(AppConstants.maxReconnectAttempts)
      //     .setReconnectionDelay(AppConstants.reconnectDelaySeconds * 1000)
      //     .build());

      _setupEventHandlers();
      _reconnectAttempts = 0;

      LogsHelper.debugLog(tag: _tag, 'Socket connection initiated');
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Socket connection error: $e');
      _scheduleReconnect();
    }
  }

  void _setupEventHandlers() {
    _onSocketEvent(SocketEvents.connect, (_) {
      LogsHelper.debugLog(tag: _tag, 'Socket connected');
      _isConnected.value = true;
      _reconnectAttempts = 0;
      _authenticate();
    });

    _onSocketEvent(SocketEvents.disconnect, (_) {
      LogsHelper.debugLog(tag: _tag, 'Socket disconnected');
      _isConnected.value = false;
      _isAuthenticated.value = false;
    });

    _onSocketEvent(SocketEvents.connectError, (error) {
      LogsHelper.debugLog(tag: _tag, 'Socket connection error: $error');
      _isConnected.value = false;
      _scheduleReconnect();
    });

    _onSocketEvent(SocketEvents.authenticated, (_) {
      LogsHelper.debugLog(tag: _tag, 'Socket authenticated');
      _isAuthenticated.value = true;
    });

    _onSocketEvent(SocketEvents.authenticationError, (error) {
      LogsHelper.debugLog(tag: _tag, 'Socket authentication error: $error');
      _isAuthenticated.value = false;
    });
  }

  Future<void> _authenticate() async {
    final accessToken = await _tokenRepository.getAccessToken();
    if (accessToken != null) {
      emit(SocketEvents.authenticate, {'token': accessToken});
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= AppConstants.maxReconnectAttempts) {
      LogsHelper.debugLog(
          tag: _tag, 'Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: AppConstants.reconnectDelaySeconds),
      () {
        _reconnectAttempts++;
        LogsHelper.debugLog(
            tag: _tag,
            'Reconnection attempt $_reconnectAttempts/${AppConstants.maxReconnectAttempts}');
        connect();
      },
    );
  }

  void _onSocketEvent(String event, Function(dynamic) handler) {
    // In actual implementation: _socket?.on(event, handler);
    _eventListeners.putIfAbsent(event, () => []).add(handler);
  }

  /// Emits an event to the server.
  void emit(String event, [dynamic data]) {
    if (!isConnected) {
      LogsHelper.debugLog(
          tag: _tag, 'Cannot emit $event: socket not connected');
      return;
    }
    // In actual implementation: _socket?.emit(event, data);
    LogsHelper.debugLog(tag: _tag, 'Emitting event: $event');
  }

  /// Listens for an event from the server.
  void on(String event, Function(dynamic) handler) {
    _onSocketEvent(event, handler);
  }

  /// Removes a specific listener for an event.
  void off(String event, [Function(dynamic)? handler]) {
    if (handler != null) {
      _eventListeners[event]?.remove(handler);
    } else {
      _eventListeners.remove(event);
    }
    // In actual implementation: _socket?.off(event, handler);
  }

  /// Joins a conversation room.
  void joinConversation(String conversationId) {
    emit(SocketEvents.joinConversation, {'conversationId': conversationId});
  }

  /// Leaves a conversation room.
  void leaveConversation(String conversationId) {
    emit(SocketEvents.leaveConversation, {'conversationId': conversationId});
  }

  /// Sends a typing indicator.
  void sendTypingIndicator(String conversationId) {
    emit(SocketEvents.startTyping, {'conversationId': conversationId});
  }

  /// Sends a stop typing indicator.
  void sendStopTypingIndicator(String conversationId) {
    emit(SocketEvents.stopTyping, {'conversationId': conversationId});
  }

  /// Disconnects the socket.
  void disconnect() {
    _reconnectTimer?.cancel();
    // In actual implementation: _socket?.disconnect();
    _isConnected.value = false;
    _isAuthenticated.value = false;
    _eventListeners.clear();
    LogsHelper.debugLog(tag: _tag, 'Socket disconnected manually');
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
