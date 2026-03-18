import 'dart:async';

import 'package:get/get.dart';

import '../../../core/data/api_response_model.dart';
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
import '../../data/types/message_status_type.dart';
import '../../data/types/message_type.dart';
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

  /// The conversation currently being viewed in chat detail (any platform).
  /// Set by ChatDetailController on entry, cleared on exit.
  /// Used to suppress unread count increments for the active chat.
  final activeConversationId = RxnString();

  /// Per-conversation typing state: conversationId → userName currently typing.
  final typingIndicators = <String, String>{}.obs;
  final Map<String, Timer> _typingTimers = {};

  // Stream subscriptions
  StreamSubscription<MessageModel>? _newMessageSub;
  StreamSubscription<Map<String, dynamic>>? _messageSentSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  StreamSubscription<Map<String, dynamic>>? _conversationUpdatedSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _messageReadSub;
  StreamSubscription<Map<String, dynamic>>? _messageDeliveredSub;
  StreamSubscription<Map<String, dynamic>>? _unreadUpdateSub;

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
    _messageSentSub?.cancel();
    _presenceSub?.cancel();
    _conversationUpdatedSub?.cancel();
    _typingSub?.cancel();
    _messageReadSub?.cancel();
    _messageDeliveredSub?.cancel();
    _unreadUpdateSub?.cancel();
    _typingTimers.forEach((_, timer) => timer.cancel());
    _typingTimers.clear();
    super.onClose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────

  Future<void> loadConversations() async {
    try {
      isLoading.value = true;

      // 1. Show cached conversations immediately
      final cached = await _chatRepository.getCachedConversations();
      if (cached.isNotEmpty) {
        conversations.value = cached;
        _sortConversations();
        isLoading.value = false;
      }

      // 2. Refresh from remote in background
      try {
        final fresh = await _chatRepository.refreshConversations();
        conversations.value = fresh;
        _sortConversations();
      } catch (e) {
        // Offline or error — cached data already displayed
        LogsHelper.debugLog(
            tag: _tag, 'Remote refresh failed (using cache): $e');
      }

      // 3. Join all conversation rooms so we receive real-time updates
      _joinAllConversationRooms();

      // 4. Query presence for all 1:1 conversation participants
      _queryParticipantPresence();
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error loading conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Queries real-time presence from the server for all other participants
  /// in 1:1 conversations. The API doesn't return live presence (it's in Redis),
  /// so we ask the socket server directly.
  void _queryParticipantPresence() {
    final userIds = <String>{};
    for (final conv in conversations) {
      if (conv.isGroup || conv.participants == null) continue;
      for (final p in conv.participants!) {
        if (p.id != currentUserId) userIds.add(p.id);
      }
    }
    if (userIds.isEmpty) return;

    _socketService.queryPresence(userIds.toList(), (result) {
      for (int i = 0; i < conversations.length; i++) {
        final conv = conversations[i];
        if (conv.isGroup || conv.participants == null) continue;

        bool changed = false;
        final updatedParticipants = List<UserModel>.from(conv.participants!);
        for (int j = 0; j < updatedParticipants.length; j++) {
          final p = updatedParticipants[j];
          final status = result[p.id];
          if (status != null) {
            final newPresence = status == 'online'
                ? UserPresence.online
                : UserPresence.offline;
            if (p.presence != newPresence) {
              updatedParticipants[j] = p.copyWith(presence: newPresence);
              changed = true;
            }
          }
        }
        if (changed) {
          conversations[i] = conv.copyWith(participants: updatedParticipants);
        }
      }
    });
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
          .where((c) => c.displayNameFor(currentUserId).toLowerCase().contains(query))
          .toList();
    }

    return result;
  }

  // ── Socket Listeners ─────────────────────────────────────────────────

  void _setupSocketListeners() {
    _newMessageSub = _socketService.onNewMessage.listen(_handleNewMessage);
    _messageSentSub = _socketService.onMessageSent.listen(_handleMessageSent);
    _presenceSub =
        _socketService.onPresenceUpdate.listen(_handlePresenceUpdate);
    _conversationUpdatedSub =
        _socketService.onConversationUpdated.listen(_handleConversationUpdated);
    _typingSub = _socketService.onTyping.listen(_handleTypingIndicator);
    _messageReadSub =
        _socketService.onMessageRead.listen(_handleMessageReadAck);
    _messageDeliveredSub =
        _socketService.onMessageDelivered.listen(_handleMessageDeliveredAck);
    _unreadUpdateSub =
        _socketService.onUnreadUpdate.listen(_handleUnreadUpdate);
  }

  /// Joins socket rooms for all loaded conversations so we receive
  /// real-time `message:new` events from the server.
  void _joinAllConversationRooms() {
    if (conversations.isEmpty) return;
    final ids = conversations.map((c) => c.id).toList();
    _socketService.joinConversations(ids);
    LogsHelper.debugLog(
        tag: _tag, 'Joined ${ids.length} conversation rooms');
  }

  void _handleNewMessage(MessageModel message) {
    final index =
        conversations.indexWhere((c) => c.id == message.conversationId);
    if (index != -1) {
      final conversation = conversations[index];
      // Don't increment unread if the user is currently viewing this chat
      // (desktop split-view uses selectedConversationId, mobile uses activeConversationId)
      final isViewing =
          selectedConversationId.value == conversation.id ||
          activeConversationId.value == conversation.id;
      conversations[index] = conversation.copyWith(
        lastMessage: message,
        lastMessageAt: message.createdAt,
        unreadCount:
            isViewing ? 0 : conversation.unreadCount + 1,
      );
      _sortConversations();
    } else {
      // New conversation from an unknown contact; reload
      loadConversations();
    }
  }

  /// Handles `message:sent` ack — updates the conversation tile for messages
  /// sent by the current user. Server now sends full message details:
  /// { localId, messageId, conversationId, senderName, type, content,
  ///   replyToId, replyToContent, replyToSenderName, createdAt }
  void _handleMessageSent(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String?;
    final conversationId = data['conversationId'] as String?;
    final createdAtStr = data['createdAt'] as String?;
    if (messageId == null || conversationId == null) return;

    final createdAt = createdAtStr != null
        ? DateTime.tryParse(createdAtStr)
        : DateTime.now();

    // Build a MessageModel from the ack data to use as lastMessage
    final sentMessage = MessageModel(
      id: messageId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: data['senderName'] as String?,
      type: MessageType.fromValue(
          (data['type'] as String?) ?? 'text'),
      content: data['content'] as String?,
      status: MessageStatusType.sent,
      replyToMessageId: data['replyToId'] as String?,
      replyToContent: data['replyToContent'] as String?,
      replyToSenderName: data['replyToSenderName'] as String?,
      createdAt: createdAt ?? DateTime.now(),
    );

    final index =
        conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      conversations[index] = conversations[index].copyWith(
        lastMessage: sentMessage,
        lastMessageAt: sentMessage.createdAt,
      );
      _sortConversations();
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

  void _handleTypingIndicator(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String?;
    final userName = data['userName'] as String? ?? 'Someone';
    final isTyping = data['isTyping'] as bool? ?? true;
    final userId = data['userId'] as String?;
    if (conversationId == null) return;

    // Ignore own typing events
    if (userId == currentUserId) return;

    // Cancel existing auto-remove timer
    _typingTimers[conversationId]?.cancel();
    _typingTimers.remove(conversationId);

    if (isTyping) {
      typingIndicators[conversationId] = userName;
      // Auto-remove after 5s (matches server Redis TTL)
      _typingTimers[conversationId] = Timer(const Duration(seconds: 5), () {
        typingIndicators.remove(conversationId);
        _typingTimers.remove(conversationId);
      });
    } else {
      typingIndicators.remove(conversationId);
    }
  }

  void _handleMessageReadAck(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String?;
    if (conversationId == null) return;

    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    final conversation = conversations[index];
    final lastMsg = conversation.lastMessage;
    if (lastMsg == null) return;

    // Update status only if the last message was sent by the current user
    if (lastMsg.senderId == currentUserId &&
        lastMsg.status != MessageStatusType.read) {
      conversations[index] = conversation.copyWith(
        lastMessage: lastMsg.copyWith(status: MessageStatusType.read),
      );
    }
  }

  void _handleMessageDeliveredAck(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String?;
    if (conversationId == null) return;

    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    final conversation = conversations[index];
    final lastMsg = conversation.lastMessage;
    if (lastMsg == null) return;

    // Only upgrade to delivered if currently at sent status
    if (lastMsg.senderId == currentUserId &&
        lastMsg.status == MessageStatusType.sent) {
      conversations[index] = conversation.copyWith(
        lastMessage: lastMsg.copyWith(status: MessageStatusType.delivered),
      );
    }
  }

  /// Handles server-driven unread count updates.
  /// The server emits 'conversation:unread:update' after marking messages
  /// as read, with { conversationId, unreadCount }.
  void _handleUnreadUpdate(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String?;
    final unreadCount = data['unreadCount'] as int? ?? 0;
    if (conversationId == null) return;

    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      conversations[index] =
          conversations[index].copyWith(unreadCount: unreadCount);
    }
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
