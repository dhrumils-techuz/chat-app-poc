import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/utils/logs_helper.dart';

/// Service for managing push notifications and local notifications.
///
/// Note: Requires the following packages in pubspec.yaml:
///   firebase_messaging: ^15.0.0
///   flutter_local_notifications: ^18.0.0
class NotificationService extends GetxService {
  static const String _tag = 'NotificationService';

  String? _fcmToken;
  final _notificationStream = StreamController<Map<String, dynamic>>.broadcast();

  String? get fcmToken => _fcmToken;
  Stream<Map<String, dynamic>> get onNotification => _notificationStream.stream;

  /// Initializes the notification service and requests permissions.
  Future<NotificationService> init() async {
    await _requestPermissions();
    await _initFCM();
    _setupNotificationHandlers();
    LogsHelper.debugLog(tag: _tag, 'Notification service initialized');
    return this;
  }

  Future<void> _requestPermissions() async {
    // In actual implementation:
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    //   provisional: false,
    // );
    LogsHelper.debugLog(tag: _tag, 'Notification permissions requested');
  }

  Future<void> _initFCM() async {
    // In actual implementation:
    // _fcmToken = await FirebaseMessaging.instance.getToken();
    // FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    //   _fcmToken = token;
    //   _onTokenRefresh(token);
    // });
    LogsHelper.debugLog(tag: _tag, 'FCM initialized, token: $_fcmToken');
  }

  void _setupNotificationHandlers() {
    // In actual implementation:
    // Handle foreground messages
    // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    //
    // Handle notification taps when app is in background
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    //
    // Handle notification taps when app is terminated
    // FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);
    LogsHelper.debugLog(tag: _tag, 'Notification handlers configured');
  }

  /// Handles a foreground notification message.
  void handleForegroundMessage(Map<String, dynamic> message) {
    LogsHelper.debugLog(tag: _tag, 'Foreground message: $message');
    _notificationStream.add(message);
    _showLocalNotification(message);
  }

  /// Handles a notification tap.
  void handleNotificationTap(Map<String, dynamic> message) {
    LogsHelper.debugLog(tag: _tag, 'Notification tapped: $message');
    final conversationId = message['conversationId'] as String?;
    if (conversationId != null) {
      _navigateToConversation(conversationId);
    }
  }

  void _showLocalNotification(Map<String, dynamic> message) {
    // In actual implementation using flutter_local_notifications:
    // final notification = message['notification'] as Map<String, dynamic>?;
    // if (notification == null) return;
    //
    // flutterLocalNotificationsPlugin.show(
    //   notification.hashCode,
    //   notification['title'],
    //   notification['body'],
    //   NotificationDetails(...),
    //   payload: json.encode(message['data']),
    // );
    LogsHelper.debugLog(tag: _tag, 'Showing local notification');
  }

  void _navigateToConversation(String conversationId) {
    // Navigate to the specific conversation
    // Get.toNamed(ChatAppRoutes.CHAT_DETAIL, arguments: conversationId);
    LogsHelper.debugLog(
        tag: _tag, 'Navigating to conversation: $conversationId');
  }

  void _onTokenRefresh(String token) {
    _fcmToken = token;
    LogsHelper.debugLog(tag: _tag, 'FCM token refreshed');
    // Should trigger saving the new token to the server
  }

  /// Subscribes to a topic for receiving group notifications.
  Future<void> subscribeToTopic(String topic) async {
    // await FirebaseMessaging.instance.subscribeToTopic(topic);
    LogsHelper.debugLog(tag: _tag, 'Subscribed to topic: $topic');
  }

  /// Unsubscribes from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    // await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    LogsHelper.debugLog(tag: _tag, 'Unsubscribed from topic: $topic');
  }

  @override
  void onClose() {
    _notificationStream.close();
    super.onClose();
  }
}
