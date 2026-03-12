class SocketEvents {
  // Connection
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String reconnect = 'reconnect';
  static const String reconnectAttempt = 'reconnect_attempt';
  static const String reconnectError = 'reconnect_error';
  static const String reconnectFailed = 'reconnect_failed';
  static const String connectError = 'connect_error';

  // Authentication
  static const String authenticate = 'authenticate';
  static const String authenticated = 'authenticated';
  static const String authenticationError = 'authentication_error';

  // Messages
  static const String sendMessage = 'send_message';
  static const String newMessage = 'new_message';
  static const String messageDelivered = 'message_delivered';
  static const String messageRead = 'message_read';
  static const String messageDeleted = 'message_deleted';
  static const String messageUpdated = 'message_updated';

  // Typing indicators
  static const String startTyping = 'start_typing';
  static const String stopTyping = 'stop_typing';
  static const String userTyping = 'user_typing';
  static const String userStoppedTyping = 'user_stopped_typing';

  // Presence
  static const String userOnline = 'user_online';
  static const String userOffline = 'user_offline';
  static const String presenceUpdate = 'presence_update';

  // Conversations
  static const String joinConversation = 'join_conversation';
  static const String leaveConversation = 'leave_conversation';
  static const String conversationUpdated = 'conversation_updated';
  static const String conversationCreated = 'conversation_created';
  static const String conversationDeleted = 'conversation_deleted';

  // Group events
  static const String memberAdded = 'member_added';
  static const String memberRemoved = 'member_removed';
  static const String memberRoleChanged = 'member_role_changed';
  static const String groupUpdated = 'group_updated';

  // Read receipts
  static const String markRead = 'mark_read';
  static const String markDelivered = 'mark_delivered';
  static const String readReceipt = 'read_receipt';
  static const String deliveryReceipt = 'delivery_receipt';

  // Error
  static const String error = 'error';
}
