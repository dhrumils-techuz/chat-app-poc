import '../../config/app_config.dart';

class ApiEndpoints {
  static String baseURL = AppConfig.apiBaseUrl;

  // Auth
  static String get _authPrefix => '$baseURL/api/auth';
  static String get login => '$_authPrefix/login';
  static String get logout => '$_authPrefix/logout';
  static String get refreshToken => '$_authPrefix/refresh';
  static String get register => '$_authPrefix/register';
  static String get forgotPassword => '$_authPrefix/forgot-password';
  static String get resetPassword => '$_authPrefix/reset-password';

  // User
  static String get _userPrefix => '$baseURL/api/users';
  static String get currentUser => '$_userPrefix/me';
  static String get updateProfile => '$_userPrefix/profile';
  static String get updateAvatar => '$_userPrefix/avatar';
  static String get searchUsers => '$_userPrefix/search';
  static String userById(String id) => '$_userPrefix/$id';

  // Conversations
  static String get _conversationPrefix => '$baseURL/api/conversations';
  static String get conversations => _conversationPrefix;
  static String conversationById(String id) => '$_conversationPrefix/$id';
  static String get createConversation => _conversationPrefix;
  static String get createGroup => _conversationPrefix; // same endpoint, type in body
  static String conversationMembers(String id) =>
      '$_conversationPrefix/$id/participants';
  static String addMember(String id) => '$_conversationPrefix/$id/participants';
  static String removeMember(String conversationId, String userId) =>
      '$_conversationPrefix/$conversationId/participants/$userId';
  static String muteConversation(String id) => '$_conversationPrefix/$id/mute';
  static String pinConversation(String id) => '$_conversationPrefix/$id/pin';
  static String archiveConversation(String id) =>
      '$_conversationPrefix/$id/archive';

  // Messages (server routes: /api/messages/:conversationId)
  static String get _messagePrefix => '$baseURL/api/messages';
  static String messagesByConversation(String conversationId) =>
      '$_messagePrefix/$conversationId';
  static String messageById(String conversationId, String messageId) =>
      '$_messagePrefix/$conversationId/$messageId';
  static String deleteMessage(String conversationId, String messageId) =>
      '$_messagePrefix/$conversationId/$messageId';
  static String markAsRead(String conversationId) =>
      '$_messagePrefix/$conversationId/read';
  static String markAsDelivered(String conversationId) =>
      '$_messagePrefix/$conversationId/delivered';

  // Media / Upload
  static String get _mediaPrefix => '$baseURL/api/media';
  static String get uploadMedia => '$_mediaPrefix/upload';
  static String get uploadAvatar => '$_mediaPrefix/avatar';
  static String get getPresignedUrl => '$_mediaPrefix/presigned-url';
  static String mediaById(String id) => '$_mediaPrefix/$id';

  // Folders
  static String get _folderPrefix => '$baseURL/api/folders';
  static String get folders => _folderPrefix;
  static String folderById(String id) => '$_folderPrefix/$id';
  static String folderConversations(String id) =>
      '$_folderPrefix/$id/conversations';

  // Device / Push Notifications
  static String get _devicePrefix => '$baseURL/api/devices';
  static String get registerDevice => _devicePrefix;
  static String get saveFcmToken => '$_devicePrefix/fcm-token';
  static String unregisterDevice(String deviceId) => '$_devicePrefix/$deviceId';
}
