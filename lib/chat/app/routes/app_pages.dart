import 'package:get/get.dart';

import '../data/auth/jwt_auth_service.dart';
import '../data/repository/auth_repository.dart';
import '../data/repository/chat_repository.dart';
import '../data/repository/folder_repository.dart';
import '../data/repository/message_repository.dart';
import '../data/repository/token_repository.dart';
import '../data/service/socket/socket_service.dart';
import '../modules/auth/sign_in/sign_in_controller.dart';
import '../modules/auth/sign_in/sign_in_screen.dart';
import '../modules/chat_detail/chat_detail_controller.dart';
import '../modules/chat_detail/chat_detail_screen.dart';
import '../modules/chat_list/chat_list_controller.dart';
import '../modules/chat_list/chat_list_screen.dart';
import '../modules/contacts/contacts_controller.dart';
import '../modules/contacts/contacts_screen.dart';
import '../modules/group/create_group/create_group_controller.dart';
import '../modules/group/create_group/create_group_screen.dart';
import '../modules/group/group_info/group_info_controller.dart';
import '../modules/group/group_info/group_info_screen.dart';
import '../modules/media_viewer/image_viewer_screen.dart';
import '../modules/profile/profile_controller.dart';
import '../modules/profile/profile_screen.dart';
import '../modules/settings/settings_controller.dart';
import '../modules/settings/settings_screen.dart';

class ChatAppPages {
  ChatAppPages._();

  static const INITIAL = ChatAppRoutes.SIGN_IN;

  static final routes = <GetPage>[
    // Auth
    GetPage(
      name: _ChatAppPaths.SIGN_IN,
      page: () => const SignInScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SignInController(
              authRepository: Get.find<AuthRepository>(),
              tokenRepository: Get.find<TokenRepository>(),
            ));
      }),
    ),

    // Chat List / Home
    GetPage(
      name: _ChatAppPaths.CHAT_LIST,
      page: () => const ChatListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ChatListController(
              chatRepository: Get.find<ChatRepository>(),
              folderRepository: Get.find<FolderRepository>(),
              socketService: Get.find<SocketService>(),
              authService: Get.find<JwtAuthService>(),
            ));
      }),
    ),

    // Chat Detail / Conversation
    GetPage(
      name: _ChatAppPaths.CHAT_DETAIL,
      page: () => const ChatDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ChatDetailController(
              messageRepository: Get.find<MessageRepository>(),
              socketService: Get.find<SocketService>(),
              authService: Get.find<JwtAuthService>(),
            ));
      }),
    ),

    // Contacts
    GetPage(
      name: _ChatAppPaths.CONTACTS,
      page: () => const ContactsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ContactsController(
              chatRepository: Get.find<ChatRepository>(),
            ));
      }),
    ),

    // New Group / Create Group
    GetPage(
      name: _ChatAppPaths.NEW_GROUP,
      page: () => const CreateGroupScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CreateGroupController(
              chatRepository: Get.find<ChatRepository>(),
            ));
      }),
    ),

    // Group Info
    GetPage(
      name: _ChatAppPaths.GROUP_INFO,
      page: () => const GroupInfoScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => GroupInfoController(
              chatRepository: Get.find<ChatRepository>(),
              authService: Get.find<JwtAuthService>(),
            ));
      }),
    ),

    // Profile
    GetPage(
      name: _ChatAppPaths.PROFILE,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileController(
              authService: Get.find<JwtAuthService>(),
            ));
      }),
    ),

    // Settings
    GetPage(
      name: _ChatAppPaths.SETTINGS,
      page: () => const SettingsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SettingsController(
              authRepository: Get.find<AuthRepository>(),
              tokenRepository: Get.find<TokenRepository>(),
              authService: Get.find<JwtAuthService>(),
            ));
      }),
    ),

    // Media Viewer
    GetPage(
      name: _ChatAppPaths.MEDIA_VIEWER,
      page: () => const ImageViewerScreen(),
    ),
  ];
}

abstract class ChatAppRoutes {
  ChatAppRoutes._();

  static const SIGN_IN = _ChatAppPaths.SIGN_IN;
  static const CHAT_LIST = _ChatAppPaths.CHAT_LIST;
  static const CHAT_DETAIL = _ChatAppPaths.CHAT_DETAIL;
  static const CONTACTS = _ChatAppPaths.CONTACTS;
  static const NEW_CHAT = _ChatAppPaths.NEW_CHAT;
  static const NEW_GROUP = _ChatAppPaths.NEW_GROUP;
  static const GROUP_INFO = _ChatAppPaths.GROUP_INFO;
  static const PROFILE = _ChatAppPaths.PROFILE;
  static const SETTINGS = _ChatAppPaths.SETTINGS;
  static const MEDIA_VIEWER = _ChatAppPaths.MEDIA_VIEWER;
  static const USER_PROFILE = _ChatAppPaths.USER_PROFILE;
}

abstract class _ChatAppPaths {
  _ChatAppPaths._();

  static const SIGN_IN = '/sign-in';
  static const CHAT_LIST = '/chat-list';
  static const CHAT_DETAIL = '/chat-detail';
  static const CONTACTS = '/contacts';
  static const NEW_CHAT = '/new-chat';
  static const NEW_GROUP = '/new-group';
  static const GROUP_INFO = '/group-info';
  static const PROFILE = '/profile';
  static const SETTINGS = '/settings';
  static const MEDIA_VIEWER = '/media-viewer';
  static const USER_PROFILE = '/user-profile';
}
