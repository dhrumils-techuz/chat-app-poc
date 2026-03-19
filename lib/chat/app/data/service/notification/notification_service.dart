import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../../../core/utils/logs_helper.dart';
import '../../../../core/utils/screen_util.dart';
import '../../model/conversation_model.dart';
import '../../repository/auth_repository.dart';
import '../../repository/chat_repository.dart';
import '../../../modules/chat_detail/chat_detail_controller.dart';
import '../../../modules/chat_list/chat_list_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/in_app_notification_banner.dart';

/// Top-level background message handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: the system tray notification is shown automatically by FCM.
  // When the user taps it, onMessageOpenedApp fires.
  debugPrint('NotificationService: Background message: ${message.messageId}');
}

/// Service for managing push notifications (FCM + local notifications).
class NotificationService extends GetxService {
  static const String _tag = 'NotificationService';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Stream of notification payloads for in-app consumption.
  final _notificationStream =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotification => _notificationStream.stream;

  /// Android notification channel for chat messages.
  /// Must match the channelId sent by the server in FCM payload.
  static const _androidChannel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'Notifications for new chat messages',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  /// Initializes FCM, local notifications, and permission requests.
  Future<NotificationService> init() async {
    try {
      await _requestPermissions();
      await _initLocalNotifications();
      await _initFCM();
      _setupNotificationHandlers();
      LogsHelper.debugLog(tag: _tag, 'Notification service initialized');
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Notification init error: $e');
    }
    return this;
  }

  // ── Permissions ──────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    LogsHelper.debugLog(
        tag: _tag, 'Notification permission: ${settings.authorizationStatus}');
  }

  // ── Local Notifications ──────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create the Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  /// Called when user taps a local notification.
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleNotificationTap(data);
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error parsing notification payload: $e');
    }
  }

  // ── FCM ──────────────────────────────────────────────────────────────

  Future<void> _initFCM() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get the FCM token
    _fcmToken = await FirebaseMessaging.instance.getToken();
    LogsHelper.debugLog(tag: _tag, 'FCM token: $_fcmToken');

    // Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _fcmToken = token;
      LogsHelper.debugLog(tag: _tag, 'FCM token refreshed');
      _saveTokenToServer(token);
    });
  }

  void _setupNotificationHandlers() {
    // Foreground messages: show local notification (FCM doesn't auto-show on foreground)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // App launched from terminated state via notification tap
    FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);
  }

  // ── Handlers ─────────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    LogsHelper.debugLog(
        tag: _tag, 'Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final conversationId = data['conversationId'] as String?;

    // Don't show notification for the conversation currently being viewed
    if (conversationId != null && Get.isRegistered<ChatDetailController>()) {
      final ctrl = Get.find<ChatDetailController>();
      if (ctrl.conversation.id == conversationId) return;
    }

    final senderName =
        data['senderName'] as String? ?? notification.title ?? 'New message';
    final conversationName = data['conversationName'] as String?;
    final conversationType = data['conversationType'] as String? ?? 'direct';
    final isGroup = conversationType == 'group';
    final groupName =
        (isGroup && conversationName != null && conversationName.isNotEmpty)
            ? conversationName
            : null;

    // 1. Show themed in-app banner overlay
    final context = Get.context;
    if (context != null) {
      final now = TimeOfDay.now();
      final timestamp =
          '${now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

      InAppNotificationBanner.show(
        context: context,
        senderName: senderName,
        body: notification.body ?? '',
        groupName: groupName,
        avatarName: isGroup ? (groupName ?? senderName) : senderName,
        timestamp: timestamp,
        onTap: () => _handleNotificationTap(data),
        duration: const Duration(milliseconds: 2500),
      );
    }

    // Emit to the in-app stream
    _notificationStream.add(data);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    LogsHelper.debugLog(tag: _tag, 'Notification opened app: ${message.data}');
    _handleNotificationTap(message.data);
  }

  void _handleInitialMessage(RemoteMessage? message) {
    if (message == null) return;
    LogsHelper.debugLog(
        tag: _tag, 'App launched from notification: ${message.data}');
    // Delay to let the app finish initializing before navigating
    Future.delayed(const Duration(seconds: 1), () {
      _handleNotificationTap(message.data);
    });
  }

  // ── Navigation ───────────────────────────────────────────────────────

  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final conversationId = data['conversationId'] as String?;
    if (conversationId == null) return;

    LogsHelper.debugLog(
        tag: _tag, 'Navigating to conversation: $conversationId');

    // If user is already viewing this conversation, do nothing.
    if (Get.isRegistered<ChatDetailController>()) {
      final currentCtrl = Get.find<ChatDetailController>();
      if (currentCtrl.conversation.id == conversationId) return;
    }

    // Determine screen type before async gap
    final context = Get.context;
    final isDesktop =
        context != null && !ScreenUtil.isMobileWidth(ScreenUtil.width(context));

    // Fetch the full conversation object from the API before navigating,
    // since ChatDetailController expects a ConversationModel as arguments.
    try {
      if (!Get.isRegistered<ChatRepository>()) return;
      final chatRepo = Get.find<ChatRepository>();
      final response = await chatRepo.getConversationById(conversationId);
      if (response.isSuccessful && response.data != null) {
        final rawData = response.data as Map<String, dynamic>;
        final convData = rawData.containsKey('data')
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
        final conversation = ConversationModel.fromJson(convData);

        // On desktop/tablet: use the split-view by setting selectedConversationId
        // on the ChatListController (no new route pushed).
        // On mobile: navigate to chat detail as a new screen.
        if (isDesktop && Get.isRegistered<ChatListController>()) {
          // Already on chat list — just select the conversation in split-view
          Get.find<ChatListController>().openChat(conversation);
        } else if (isDesktop) {
          // Not on chat list yet — navigate there, then select
          Get.offAllNamed(ChatAppRoutes.CHAT_LIST);
          await Future.delayed(const Duration(milliseconds: 300));
          if (Get.isRegistered<ChatListController>()) {
            Get.find<ChatListController>().openChat(conversation);
          }
        } else {
          // Mobile: pop back to chat list, then push chat detail
          Get.until((route) =>
              route.settings.name == ChatAppRoutes.CHAT_LIST || route.isFirst);
          Get.toNamed(
            ChatAppRoutes.CHAT_DETAIL,
            arguments: conversation,
          );
        }
      }
    } catch (e) {
      LogsHelper.debugLog(
          tag: _tag, 'Error fetching conversation for notification: $e');
    }
  }

  // ── Token Management ─────────────────────────────────────────────────

  /// Saves the current FCM token to the server.
  /// Called after login and on token refresh.
  Future<void> saveTokenToServer() async {
    if (_fcmToken == null) return;
    await _saveTokenToServer(_fcmToken!);
  }

  Future<void> _saveTokenToServer(String token) async {
    try {
      if (!Get.isRegistered<AuthRepository>()) return;
      final authRepo = Get.find<AuthRepository>();
      await authRepo.saveFcmToken(
        deviceType: Platform.isAndroid ? 1 : 2,
        fcmToken: token,
      );
      LogsHelper.debugLog(tag: _tag, 'FCM token saved to server');
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error saving FCM token: $e');
    }
  }

  @override
  void onClose() {
    _notificationStream.close();
    super.onClose();
  }
}
