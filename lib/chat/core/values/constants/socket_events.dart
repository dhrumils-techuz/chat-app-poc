class SocketEvents {
  // Connection (built-in socket.io events — remain unchanged)
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String reconnect = 'reconnect';
  static const String reconnectAttempt = 'reconnect_attempt';
  static const String reconnectError = 'reconnect_error';
  static const String reconnectFailed = 'reconnect_failed';
  static const String connectError = 'connect_error';

  // ── Client → Server events ────────────────────────────────────────────

  // Messages
  static const String sendMessage = 'message:send';
  static const String messageDelivered = 'message:delivered';
  static const String messageRead = 'message:read';

  // Typing
  static const String startTyping = 'typing:start';
  static const String stopTyping = 'typing:stop';

  // Presence
  static const String presenceOnline = 'presence:online';
  static const String presenceOffline = 'presence:offline';

  // Conversations
  static const String joinConversations = 'conversations:join';

  // ── Server → Client events ────────────────────────────────────────────

  // Messages
  static const String messageNew = 'message:new';
  static const String messageSent = 'message:sent';
  static const String messageDeliveredAck = 'message:delivered:ack';
  static const String messageReadAck = 'message:read:ack';

  // Typing
  static const String typingIndicator = 'typing:indicator';

  // Presence
  static const String presenceUpdate = 'presence:update';

  // Error
  static const String error = 'error';
}
