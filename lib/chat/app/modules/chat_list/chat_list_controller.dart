import 'dart:async';

import 'package:get/get.dart';

import '../../../core/data/api_response_model.dart';
import '../../../core/data/paginated_response.dart';
import '../../../core/utils/logs_helper.dart';
import '../../../core/utils/screen_util.dart';
import '../../data/auth/jwt_auth_service.dart';
import '../../data/model/chat_folder_model.dart';
import '../../data/model/conversation_model.dart';
import '../../data/model/message_model.dart';
import '../../data/model/user_model.dart';
import '../../data/repository/chat_repository.dart';
import '../../data/repository/folder_repository.dart';
import '../../data/service/socket/socket_service.dart';
import '../../data/types/user_presence.dart';
import '../../routes/app_pages.dart';

class ChatListController extends GetxController {
  static const String _tag = 'ChatListController';

  final ChatRepository _chatRepository;
  final FolderRepository _folderRepository;
  final SocketService _socketService;
  final JwtAuthService _authService;

  ChatListController({
    required ChatRepository chatRepository,
    required FolderRepository folderRepository,
    required SocketService socketService,
    required JwtAuthService authService,
  })  : _chatRepository = chatRepository,
        _folderRepository = folderRepository,
        _socketService = socketService,
        _authService = authService;

  // Observable state
  final conversations = <ConversationModel>[].obs;
  final folders = <ChatFolderModel>[].obs;
  final selectedFolderIndex = 0.obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final selectedConversationId = RxnString();

  // Stream subscriptions
  StreamSubscription<MessageModel>? _newMessageSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  StreamSubscription<Map<String, dynamic>>? _conversationUpdatedSub;

  String get currentUserId => _authService.currentUserId ?? '';

  @override
  void onInit() {
    super.onInit();
    loadConversations();
    loadFolders();
    _initSocket();
  }

  /// Initializes the socket connection and sets up listeners.
  /// Safe to call multiple times — the socket will only connect once.
  Future<void> _initSocket() async {
    await _socketService.init();
    _setupSocketListeners();
  }

  @override
  void onClose() {
    _newMessageSub?.cancel();
    _presenceSub?.cancel();
    _conversationUpdatedSub?.cancel();
    super.onClose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────

  Future<void> loadConversations() async {
    try {
      isLoading.value = true;
      final ApiResponseModel response =
          await _chatRepository.getConversations();

      if (response.isSuccessful && response.data != null) {
        final paginated = PaginatedResponse<ConversationModel>.fromJson(
          response.data as Map<String, dynamic>,
          (json) => ConversationModel.fromJson(json),
        );
        conversations.value = paginated.items;
        _sortConversations();
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error loading conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFolders() async {
    try {
      final ApiResponseModel response = await _folderRepository.getFolders();

      if (response.isSuccessful && response.data != null) {
        final rawData = response.data;
        final List folderData = rawData is Map
            ? (rawData['data'] as List? ?? [])
            : (rawData as List);
        final folderList = folderData
            .map((e) => ChatFolderModel.fromJson(e as Map<String, dynamic>))
            .toList();
        folders.value = folderList;
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error loading folders: $e');
    }
  }

  Future<void> refreshConversations() async {
    await loadConversations();
  }

  // ── Filtered Conversations ────────────────────────────────────────────

  List<ConversationModel> get filteredConversations {
    List<ConversationModel> result = List.from(conversations);

    // Filter by selected folder
    if (selectedFolderIndex.value > 0) {
      final folderIdx = selectedFolderIndex.value - 1;
      if (folderIdx < folders.length) {
        final folder = folders[folderIdx];
        result = result
            .where((c) => folder.conversationIds.contains(c.id))
            .toList();
      }
    }

    // Filter by search query
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result
          .where((c) => c.displayName.toLowerCase().contains(query))
          .toList();
    }

    return result;
  }

  // ── Socket Listeners ─────────────────────────────────────────────────

  void _setupSocketListeners() {
    _newMessageSub = _socketService.onNewMessage.listen(_handleNewMessage);
    _presenceSub =
        _socketService.onPresenceUpdate.listen(_handlePresenceUpdate);
    _conversationUpdatedSub =
        _socketService.onConversationUpdated.listen(_handleConversationUpdated);
  }

  void _handleNewMessage(MessageModel message) {
    final index =
        conversations.indexWhere((c) => c.id == message.conversationId);
    if (index != -1) {
      final conversation = conversations[index];
      final isSelected =
          selectedConversationId.value == conversation.id;
      conversations[index] = conversation.copyWith(
        lastMessage: message,
        lastMessageAt: message.createdAt,
        unreadCount:
            isSelected ? 0 : conversation.unreadCount + 1,
      );
      _sortConversations();
    } else {
      // New conversation from an unknown contact; reload
      loadConversations();
    }
  }

  void _handlePresenceUpdate(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    final status = data['status'] as String?;
    if (userId == null || status == null) return;

    for (int i = 0; i < conversations.length; i++) {
      final conversation = conversations[i];
      if (conversation.participants == null) continue;

      final participantIndex =
          conversation.participants!.indexWhere((p) => p.id == userId);
      if (participantIndex != -1) {
        final updatedParticipants =
            List<UserModel>.from(conversation.participants!);
        updatedParticipants[participantIndex] =
            updatedParticipants[participantIndex].copyWith(
          presence: status == 'online'
              ? UserPresence.online
              : UserPresence.offline,
        );
        conversations[i] =
            conversation.copyWith(participants: updatedParticipants);
      }
    }
  }

  void _handleConversationUpdated(Map<String, dynamic> data) {
    // Reload to get the latest state
    loadConversations();
  }

  // ── Actions ───────────────────────────────────────────────────────────

  void openChat(ConversationModel conversation) {
    // On desktop width, update the selected id for split view
    final context = Get.context;
    if (context != null && !ScreenUtil.isMobileWidth(ScreenUtil.width(context))) {
      selectedConversationId.value = conversation.id;
    } else {
      Get.toNamed(ChatAppRoutes.CHAT_DETAIL, arguments: conversation);
    }
  }

  void searchConversations(String query) {
    searchQuery.value = query;
  }

  void onFolderTap(int index) {
    selectedFolderIndex.value = index;
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _sortConversations() {
    conversations.sort((a, b) {
      // Pinned conversations first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // Then by last message time (most recent first)
      final aTime = a.lastMessageAt ?? a.createdAt ?? DateTime(2000);
      final bTime = b.lastMessageAt ?? b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
  }

  /// Returns whether a participant in a 1:1 conversation is online.
  bool isConversationOnline(ConversationModel conversation) {
    if (conversation.isGroup) return false;
    if (conversation.participants == null) return false;
    final other = conversation.participants!
        .where((p) => p.id != currentUserId)
        .toList();
    if (other.isEmpty) return false;
    return other.first.presence.isOnline;
  }
}
