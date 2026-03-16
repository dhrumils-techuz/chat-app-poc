import 'dart:async';

import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../core/config/app_config.dart';
import '../../../core/utils/logs_helper.dart';
import '../../../core/values/constants/app_constants.dart';
import '../../../core/values/constants/socket_events.dart';
import '../repository/token_repository.dart';

/// Socket.IO wrapper service that manages the WebSocket connection.
///
/// Authentication is done via the handshake `auth` option (NOT a separate event).
/// The server validates the JWT token in the Socket.IO middleware before the
/// `connection` event fires, so on connect the socket is already authenticated.
///
/// Listeners registered via [on] before [connect] are stored and applied
/// to the socket instance once it is created, ensuring no events are missed.
class SocketClient extends GetxService {
  static const String _tag = 'SocketClient';

  final TokenRepository _tokenRepository;

  IO.Socket? _socket;

  final _isConnected = false.obs;
  final _isAuthenticated = false.obs;

  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  /// Listeners registered before the socket is created.
  /// They are applied to the socket in [connect] before calling socket.connect().
  final Map<String, List<Function(dynamic)>> _pendingListeners = {};

  bool get isConnected => _isConnected.value;
  bool get isAuthenticated => _isAuthenticated.value;

  SocketClient(this._tokenRepository);

  /// Initializes the socket connection with authentication via handshake.
  ///
  /// The server uses Socket.IO middleware to extract the token from
  /// `socket.handshake.auth.token` and verifies it before the connection
  /// event fires. No separate "authenticate" event is needed.
  Future<void> connect() async {
    // Don't reconnect if already connected
    if (_socket != null && _isConnected.value) {
      LogsHelper.debugLog(tag: _tag, 'Socket already connected');
      return;
    }

    final accessToken = await _tokenRepository.getAccessToken();
    if (accessToken == null) {
      LogsHelper.debugLog(
          tag: _tag, 'No access token available for socket connection');
      return;
    }

    try {
      // Dispose previous socket if any
      _socket?.dispose();

      _socket = IO.io(
        AppConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': accessToken})
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(AppConstants.maxReconnectAttempts)
            .setReconnectionDelay(AppConstants.reconnectDelaySeconds * 1000)
            .build(),
      );

      // 1. Set up internal connection handlers
      _setupEventHandlers();

      // 2. Apply any listeners registered before socket was created
      _applyPendingListeners();

      // 3. Now connect — all listeners are in place, no events will be missed
      _socket!.connect();
      _reconnectAttempts = 0;

      LogsHelper.debugLog(tag: _tag, 'Socket connection initiated');
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Socket connection error: $e');
      _scheduleReconnect();
    }
  }

  void _setupEventHandlers() {
    final socket = _socket;
    if (socket == null) return;

    socket.onConnect((_) {
      LogsHelper.debugLog(
          tag: _tag, 'Socket connected (authenticated via handshake)');
      _isConnected.value = true;
      _isAuthenticated.value = true;
      _reconnectAttempts = 0;
    });

    socket.onDisconnect((_) {
      LogsHelper.debugLog(tag: _tag, 'Socket disconnected');
      _isConnected.value = false;
      _isAuthenticated.value = false;
    });

    socket.onConnectError((error) {
      LogsHelper.debugLog(tag: _tag, 'Socket connection error: $error');
      _isConnected.value = false;
      _isAuthenticated.value = false;
      _scheduleReconnect();
    });

    socket.onError((data) {
      LogsHelper.debugLog(tag: _tag, 'Socket error: $data');
    });

    socket.onReconnect((_) {
      LogsHelper.debugLog(tag: _tag, 'Socket reconnected');
      _isConnected.value = true;
      _isAuthenticated.value = true;
      _reconnectAttempts = 0;
    });

    socket.onReconnectAttempt((attempt) {
      LogsHelper.debugLog(tag: _tag, 'Socket reconnect attempt: $attempt');
    });

    socket.onReconnectError((error) {
      LogsHelper.debugLog(tag: _tag, 'Socket reconnect error: $error');
    });

    socket.onReconnectFailed((_) {
      LogsHelper.debugLog(tag: _tag, 'Socket reconnect failed');
    });
  }

  /// Applies all listeners that were registered before the socket was created.
  void _applyPendingListeners() {
    final socket = _socket;
    if (socket == null) return;

    _pendingListeners.forEach((event, handlers) {
      for (final handler in handlers) {
        socket.on(event, handler);
      }
    });
    // Keep them so they can be re-applied on reconnect with new token
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= AppConstants.maxReconnectAttempts) {
      LogsHelper.debugLog(tag: _tag, 'Max reconnection attempts reached');
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

  /// Emits an event to the server.
  void emit(String event, [dynamic data]) {
    if (!isConnected || _socket == null) {
      LogsHelper.debugLog(
          tag: _tag, 'Cannot emit $event: socket not connected');
      return;
    }
    if (data != null) {
      _socket!.emit(event, data);
    } else {
      _socket!.emit(event);
    }
  }

  /// Emits an event with an acknowledgement callback.
  void emitWithAck(String event, dynamic data, Function(dynamic) callback) {
    if (!isConnected || _socket == null) {
      LogsHelper.debugLog(
          tag: _tag, 'Cannot emit $event: socket not connected');
      return;
    }
    _socket!.emitWithAck(event, data, ack: callback);
  }

  /// Listens for an event from the server.
  ///
  /// If the socket is not yet created, the listener is stored and applied
  /// once [connect] creates the socket instance.
  void on(String event, Function(dynamic) handler) {
    // Always store in pending so they can be re-applied on reconnect
    _pendingListeners.putIfAbsent(event, () => []).add(handler);
    // If socket exists, also register immediately
    _socket?.on(event, handler);
  }

  /// Removes a specific listener for an event.
  void off(String event, [Function(dynamic)? handler]) {
    if (handler != null) {
      _pendingListeners[event]?.remove(handler);
      _socket?.off(event, handler);
    } else {
      _pendingListeners.remove(event);
      _socket?.off(event);
    }
  }

  /// Joins conversation rooms.
  /// Server expects `conversations:join` with `{ conversationIds: string[] }`.
  void joinConversation(String conversationId) {
    emit(SocketEvents.joinConversations, {
      'conversationIds': [conversationId],
    });
  }

  /// Joins multiple conversation rooms at once.
  void joinConversations(List<String> conversationIds) {
    if (conversationIds.isEmpty) return;
    emit(SocketEvents.joinConversations, {
      'conversationIds': conversationIds,
    });
  }

  /// Sends a typing indicator.
  void sendTypingIndicator(String conversationId) {
    emit(SocketEvents.startTyping, {'conversationId': conversationId});
  }

  /// Sends a stop typing indicator.
  void sendStopTypingIndicator(String conversationId) {
    emit(SocketEvents.stopTyping, {'conversationId': conversationId});
  }

  /// Reconnects the socket with a fresh token.
  /// Useful after token refresh or re-authentication.
  Future<void> reconnectWithNewToken() async {
    disconnect();
    await connect();
  }

  /// Disconnects the socket.
  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.dispose();
    _socket = null;
    _isConnected.value = false;
    _isAuthenticated.value = false;
    LogsHelper.debugLog(tag: _tag, 'Socket disconnected manually');
  }

  @override
  void onClose() {
    disconnect();
    _pendingListeners.clear();
    super.onClose();
  }
}
