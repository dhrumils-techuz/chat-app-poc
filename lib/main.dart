import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SharedPreferenceHelper.init();

  // ── Core services (permanent) ────────────────────────────────────────

  final tokenRepository = await Get.put(TokenRepository(), permanent: true).init();

  final dioClient = Get.put(
    DioRemoteApiClient(tokenRepository),
    permanent: true,
  );

  final socketClient = Get.put(
    SocketClient(tokenRepository),
    permanent: true,
  );

  // ── Remote services (lazy) ───────────────────────────────────────────

  Get.lazyPut(() => DioAuthService(dioClient: dioClient));
  Get.lazyPut(() => DioChatService(dioClient: dioClient));
  Get.lazyPut(() => DioMessageService(dioClient: dioClient));
  Get.lazyPut(() => DioMediaService(dioClient: dioClient));

  // ── Repositories (lazy) ──────────────────────────────────────────────

  Get.lazyPut(() => AuthRepository(authService: Get.find<DioAuthService>()));
  Get.lazyPut(() => ChatRepository(chatService: Get.find<DioChatService>()));
  Get.lazyPut(
    () => MessageRepository(messageService: Get.find<DioMessageService>()),
  );
  Get.lazyPut(
    () => MediaRepository(mediaService: Get.find<DioMediaService>()),
  );
  Get.lazyPut(
    () => FolderRepository(chatService: Get.find<DioChatService>()),
  );

  // ── Auth & socket services (permanent) ───────────────────────────────

  Get.put(JwtAuthService(tokenRepository), permanent: true);

  Get.put(SocketService(socketClient), permanent: true);

  Get.lazyPut(() => NotificationService());

  // ── Run app ──────────────────────────────────────────────────────────

  runApp(
    GetMaterialApp(
      title: 'Medical Chat',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ).copyWith(
        extensions: [const ChatColors.light()],
      ),
      initialRoute: ChatAppRoutes.SIGN_IN,
      getPages: ChatAppPages.routes,
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,
    ),
  );
}
