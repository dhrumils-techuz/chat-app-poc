import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat/core/config/app_config.dart';
import 'chat/app/data/auth/jwt_auth_service.dart';
import 'chat/app/data/client/dio_remote_api_client.dart';
import 'chat/app/data/client/socket_client.dart';
import 'chat/app/data/local/database/app_database.dart';
import 'chat/app/data/local/database/dao/conversation_dao.dart';
import 'chat/app/data/local/database/dao/message_dao.dart';
import 'chat/app/data/local/database/dao/pending_message_dao.dart';
import 'chat/app/data/local/database/dao/user_dao.dart';
import 'chat/app/data/repository/auth_repository.dart';
import 'chat/app/data/repository/chat_repository.dart';
import 'chat/app/data/repository/folder_repository.dart';
import 'chat/app/data/repository/media_repository.dart';
import 'chat/app/data/repository/message_repository.dart';
import 'chat/app/data/repository/token_repository.dart';
import 'chat/app/data/service/auth/dio_auth_service.dart';
import 'chat/app/data/service/chat/dio_chat_service.dart';
import 'chat/app/data/service/connectivity/connectivity_service.dart';
import 'chat/app/data/service/media/dio_media_service.dart';
import 'chat/app/data/service/message/dio_message_service.dart';
import 'chat/app/data/service/notification/notification_service.dart';
import 'chat/app/data/service/socket/socket_service.dart';
import 'chat/app/data/service/sync/message_sync_service.dart';
import 'chat/app/routes/app_pages.dart';
import 'chat/core/theme/color.dart';
import 'chat/core/utils/shared_preference_helper.dart';
import 'chat/core/values/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from assets/.env
  await AppConfig.load();

  // Firebase is optional — only needed for push notifications.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }
  await SharedPreferenceHelper.init();

  // ── Local database (encrypted, HIPAA-compliant) ─────────────────────

  final appDatabase =
      await Get.put(AppDatabase(), permanent: true).init();

  // ── DAOs ────────────────────────────────────────────────────────────

  final conversationDao = Get.put(ConversationDao(appDatabase), permanent: true);
  final messageDao = Get.put(MessageDao(appDatabase), permanent: true);
  final userDao = Get.put(UserDao(appDatabase), permanent: true);
  final pendingMessageDao =
      Get.put(PendingMessageDao(appDatabase), permanent: true);

  // ── Core services (permanent) ────────────────────────────────────────

  final tokenRepository =
      await Get.put(TokenRepository(), permanent: true).init();

  final dioClient = Get.put(
    DioRemoteApiClient(tokenRepository),
    permanent: true,
  );

  final socketClient = Get.put(
    SocketClient(tokenRepository),
    permanent: true,
  );

  // ── Connectivity service ────────────────────────────────────────────

  final connectivityService =
      await Get.put(ConnectivityService(), permanent: true).init();

  // ── Remote services (lazy, fenix for re-creation) ───────────────────

  Get.lazyPut(() => DioAuthService(dioClient: dioClient), fenix: true);
  Get.lazyPut(() => DioChatService(dioClient: dioClient), fenix: true);
  Get.lazyPut(() => DioMessageService(dioClient: dioClient), fenix: true);
  Get.lazyPut(() => DioMediaService(dioClient: dioClient), fenix: true);

  // ── Repositories (lazy, fenix for re-creation) ─────────────────────

  Get.lazyPut(() => AuthRepository(authService: Get.find<DioAuthService>()),
      fenix: true);
  Get.lazyPut(
    () => ChatRepository(
      chatService: Get.find<DioChatService>(),
      conversationDao: conversationDao,
      userDao: userDao,
    ),
    fenix: true,
  );
  Get.lazyPut(
    () => MessageRepository(
      messageService: Get.find<DioMessageService>(),
      messageDao: messageDao,
      pendingMessageDao: pendingMessageDao,
    ),
    fenix: true,
  );
  Get.lazyPut(
    () => MediaRepository(mediaService: Get.find<DioMediaService>()),
    fenix: true,
  );
  Get.lazyPut(
    () => FolderRepository(chatService: Get.find<DioChatService>()),
    fenix: true,
  );

  // ── Auth & socket services (permanent) ───────────────────────────────

  final authService = Get.put(JwtAuthService(tokenRepository), permanent: true);

  // Restore user session from persisted storage (if user was logged in before).
  await authService.restoreSession();

  final socketService = Get.put(SocketService(socketClient), permanent: true);

  Get.lazyPut(() => NotificationService());

  // ── Sync service (permanent, starts background listeners) ───────────

  await Get.put(
    MessageSyncService(
      connectivityService,
      socketService,
      messageDao,
      pendingMessageDao,
      conversationDao,
    ),
    permanent: true,
  ).init();

  // ── Connect socket early if user is already logged in ─────────────
  // This ensures the socket is connected before any screen tries to
  // join rooms or send events, avoiding "socket not connected yet" queuing.
  if (authService.isLoggedIn) {
    socketService.init(); // Fire-and-forget — connects asynchronously
  }

  // ── Run app ──────────────────────────────────────────────────────────

  runApp(
    GetMaterialApp(
      title: Keys.AppName.tr,
      translations: ChatMessages(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        primarySwatch: MaterialColor(AppColor.primary.value, const {
          50: Color(0xFFE8F8F0),
          100: Color(0xFFC6EDDA),
          200: Color(0xFFA0E1C1),
          300: Color(0xFF7AD5A8),
          400: Color(0xFF5ECB95),
          500: AppColor.primary,
          600: Color(0xFF0EB075),
          700: Color(0xFF0C9B6A),
          800: Color(0xFF0A875F),
          900: Color(0xFF066547),
        }),
      ).copyWith(
        extensions: [const ChatColors.light()],
      ),
      initialRoute: authService.isLoggedIn
          ? ChatAppRoutes.CHAT_LIST
          : ChatAppRoutes.SIGN_IN,
      getPages: ChatAppPages.routes,
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,
    ),
  );
}
