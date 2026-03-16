import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat/core/config/app_config.dart';
import 'chat/app/data/auth/jwt_auth_service.dart';
import 'chat/app/data/client/dio_remote_api_client.dart';
import 'chat/app/data/client/socket_client.dart';
import 'chat/app/data/repository/auth_repository.dart';
import 'chat/app/data/repository/chat_repository.dart';
import 'chat/app/data/repository/folder_repository.dart';
import 'chat/app/data/repository/media_repository.dart';
import 'chat/app/data/repository/message_repository.dart';
import 'chat/app/data/repository/token_repository.dart';
import 'chat/app/data/service/auth/dio_auth_service.dart';
import 'chat/app/data/service/chat/dio_chat_service.dart';
import 'chat/app/data/service/media/dio_media_service.dart';
import 'chat/app/data/service/message/dio_message_service.dart';
import 'chat/app/data/service/notification/notification_service.dart';
import 'chat/app/data/service/socket/socket_service.dart';
import 'chat/app/routes/app_pages.dart';
import 'chat/core/theme/color.dart';
import 'chat/core/utils/shared_preference_helper.dart';
import 'chat/core/values/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from assets/.env
  await AppConfig.load();

  // Firebase is optional — only needed for push notifications.
  // If google-services.json / GoogleService-Info.plist is not configured,
  // the app will still run without push notification support.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }
  await SharedPreferenceHelper.init();

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

  // ── Remote services (lazy, fenix for re-creation) ───────────────────

  Get.lazyPut(() => DioAuthService(dioClient: dioClient), fenix: true);
  Get.lazyPut(() => DioChatService(dioClient: dioClient), fenix: true);
  Get.lazyPut(() => DioMessageService(dioClient: dioClient), fenix: true);
  Get.lazyPut(() => DioMediaService(dioClient: dioClient), fenix: true);

  // ── Repositories (lazy, fenix for re-creation) ─────────────────────

  Get.lazyPut(() => AuthRepository(authService: Get.find<DioAuthService>()),
      fenix: true);
  Get.lazyPut(() => ChatRepository(chatService: Get.find<DioChatService>()),
      fenix: true);
  Get.lazyPut(
    () => MessageRepository(messageService: Get.find<DioMessageService>()),
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
  // This ensures currentUserId is available immediately on app restart.
  await authService.restoreSession();

  Get.put(SocketService(socketClient), permanent: true);

  Get.lazyPut(() => NotificationService());

  // ── Run app ──────────────────────────────────────────────────────────

  runApp(
    GetMaterialApp(
      title: Keys.AppName.tr,
      translations: ChatMessages(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        primarySwatch: Colors.green,
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
