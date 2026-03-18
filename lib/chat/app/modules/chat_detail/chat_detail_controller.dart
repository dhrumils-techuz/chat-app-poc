import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/data/api_response_model.dart';
import '../../../core/theme/color.dart';
import '../../../core/utils/logs_helper.dart';
import '../../../core/values/app_strings.dart';
import '../../data/auth/jwt_auth_service.dart';
import '../../data/model/conversation_model.dart';
import '../chat_list/chat_list_controller.dart';
import '../../data/model/media_attachment_model.dart';
import '../../data/model/message_model.dart';
import '../../data/model/user_model.dart';
import '../../data/repository/message_repository.dart';
import '../../data/service/socket/socket_service.dart';
import '../../data/types/message_status_type.dart';
import '../../data/types/message_type.dart';
import '../../data/types/user_presence.dart';

class ChatDetailController extends GetxController {
  static const String _tag = 'ChatDetailController';

  final MessageRepository _messageRepository;
  final SocketService _socketService;
  final JwtAuthService _authService;

  /// Optional conversation passed directly (used in desktop split-view).
  /// When null, falls back to `Get.arguments`.
  final ConversationModel? _conversationOverride;

  ChatDetailController({
    required MessageRepository messageRepository,
    required SocketService socketService,
    required JwtAuthService authService,
    ConversationModel? conversation,
  })  : _messageRepository = messageRepository,
        _socketService = socketService,
        _authService = authService,
        _conversationOverride = conversation;

  // ── Conversation ───────────────────────────────────────────────────────
  late final Rx<ConversationModel> _conversation;
  ConversationModel get conversation => _conversation.value;

  // ── Observable State ───────────────────────────────────────────────────
  final messages = <MessageModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isSendingMessage = false.obs;
  final isRecording = false.obs;
  final messageText = ''.obs;
  final replyingTo = Rxn<MessageModel>();
  final typingUsers = <String>[].obs;
  final hasMoreMessages = true.obs;
  final highlightedMessageId = RxnString();
  final showScrollToBottom = false.obs;

  // ── Search State ─────────────────────────────────────────────────────
  final isSearching = false.obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  final isSearchLoading = false.obs;
  Timer? _searchDebounce;

  /// Whether we jumped to an old message and the list is not at the latest.
  final isViewingOldMessages = false.obs;

  // ── Controllers ────────────────────────────────────────────────────────
  final textController = TextEditingController();

  /// Item-level scroll controller from scrollable_positioned_list.
  /// Allows scrolling/jumping to any item by index — no GlobalKey needed.
  final itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();

  /// Reactive presence status for the other participant in 1:1 conversations.
  final otherUserPresence = UserPresence.offline.obs;

  // ── Stream Subscriptions ───────────────────────────────────────────────
  StreamSubscription<MessageModel>? _newMessageSub;
  StreamSubscription<Map<String, dynamic>>? _messageSentSub;
  StreamSubscription<Map<String, dynamic>>? _messageDeliveredSub;
  StreamSubscription<Map<String, dynamic>>? _messageReadSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _messageDeletedSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  StreamSubscription<Map<String, dynamic>>? _conversationUpdatedSub;

  // ── Typing Debounce ────────────────────────────────────────────────────
  Timer? _typingDebounce;
  bool _isCurrentlyTyping = false;

  // ── Pagination ─────────────────────────────────────────────────────────
  String? _nextCursor;
  static const int _pageSize = 50;

  // ── Computed Properties ────────────────────────────────────────────────
  String get currentUserId => _authService.currentUserId ?? '';
  bool get isGroup => conversation.isGroup;

  @override
  void onInit() {
    super.onInit();
    _conversation = Rx<ConversationModel>(
        _conversationOverride ?? Get.arguments as ConversationModel);

    // Initialize presence from local data first (may be stale),
    // then query the server for the real-time status.
    final other = otherParticipant;
    if (other != null) {
      // Check ChatListController's live data first
      if (Get.isRegistered<ChatListController>()) {
        final listCtrl = Get.find<ChatListController>();
        final liveConv = listCtrl.conversations.firstWhereOrNull(
          (c) => c.id == conversation.id,
        );
        if (liveConv?.participants != null) {
          final liveOther = liveConv!.participants!
              .where((p) => p.id != currentUserId)
              .toList();
          if (liveOther.isNotEmpty) {
            otherUserPresence.value = liveOther.first.presence;
          }
        }
      }

      // Query the server for the actual real-time presence from Redis.
      // This ensures we get the correct status even if the presence:update
      // event was broadcast before we started listening.
      _socketService.queryPresence([other.id], (result) {
        final status = result[other.id];
        if (status != null) {
          otherUserPresence.value = UserPresence.fromValue(status);
        }
      });
    }
    _socketService.joinConversation(conversation.id);
    // Tell the chat list this conversation is currently being viewed,
    // so it won't increment unread count for incoming messages.
    if (Get.isRegistered<ChatListController>()) {
      Get.find<ChatListController>().activeConversationId.value = conversation.id;
    }
    loadMessages(); // _markAllAsRead is called after messages load
    _setupSocketListeners();
    // Listen to visible item positions for load-more and scroll-to-bottom.
    itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
  }

  /// Whether this controller has been closed (disposed).
  /// Used by the view layer to avoid accessing disposed controllers.
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  @override
  void onClose() {
    _isDisposed = true;
    _socketService.leaveConversation(conversation.id);
    // Clear the active conversation so the chat list resumes counting unreads
    if (Get.isRegistered<ChatListController>()) {
      final listCtrl = Get.find<ChatListController>();
      if (listCtrl.activeConversationId.value == conversation.id) {
        listCtrl.activeConversationId.value = null;
      }
    }
    _newMessageSub?.cancel();
    _messageSentSub?.cancel();
    _messageDeliveredSub?.cancel();
    _messageReadSub?.cancel();
    _typingSub?.cancel();
    _messageDeletedSub?.cancel();
    _presenceSub?.cancel();
    _conversationUpdatedSub?.cancel();
    _typingDebounce?.cancel();
    _searchDebounce?.cancel();
    if (_isCurrentlyTyping) {
      _socketService.stopTyping(conversation.id);
    }
    itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    // Defer disposal of UI controllers with a delay to let the focus system
    // finish processing. Using Future.delayed instead of addPostFrameCallback
    // because FocusManager.applyFocusChangesIfNeeded runs in post-frame
    // callbacks too and may reference the TextEditingController.
    Future.delayed(const Duration(milliseconds: 200), () {
      try {
        textController.dispose();
      } catch (_) {}
    });
    super.onClose();
  }

  // ── Data Loading ───────────────────────────────────────────────────────

  Future<void> loadMessages({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        isLoading.value = true;
        _nextCursor = null;

        // 1. Show cached messages immediately
        final cached = await _messageRepository.getCachedMessages(
          conversation.id,
        );
        if (cached.isNotEmpty) {
          messages.value = cached;
          isLoading.value = false;
        }
      }

      // 2. Fetch from remote
      final ApiResponseModel response = await _messageRepository.getMessages(
        conversationId: conversation.id,
        limit: _pageSize,
        cursor: loadMore ? _nextCursor : null,
      );

      if (response.isSuccessful && response.data != null) {
        final rawData = response.data as Map<String, dynamic>;
        final List messageList = rawData['data'] as List? ?? [];
        final parsedMessages = messageList
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList();

        if (loadMore) {
          messages.addAll(parsedMessages);
        } else {
          messages.value = parsedMessages;
        }

        _nextCursor = rawData['nextCursor'] as String?;
        hasMoreMessages.value = rawData['hasMore'] as bool? ?? false;

        // 3. Cache fetched messages locally
        _messageRepository.cacheMessages(parsedMessages);
      }
    } catch (e) {
      // Offline or error — cached data already displayed
      LogsHelper.debugLog(tag: _tag, 'Error loading messages: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;

      // Mark messages as read now that we have them loaded
      if (!loadMore) {
        _markAllAsRead();
      }
    }
  }

  Future<void> loadMoreMessages() async {
    if (isLoadingMore.value || !hasMoreMessages.value) return;

    isLoadingMore.value = true;
    await loadMessages(loadMore: true);
  }

  // ── Sending Messages ──────────────────────────────────────────────────

  void sendTextMessage() {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final message = MessageModel(
      id: tempId,
      conversationId: conversation.id,
      senderId: currentUserId,
      senderName: _authService.currentUser?.name,
      type: MessageType.text,
      content: text,
      status: MessageStatusType.sending,
      replyToMessageId: replyingTo.value?.id,
      replyToContent: replyingTo.value?.content,
      replyToSenderName: replyingTo.value?.senderName,
      createdAt: DateTime.now(),
    );

    // Optimistic insert at the beginning (newest first)
    messages.insert(0, message);
    textController.clear();
    messageText.value = '';
    cancelReply();
    _scrollToBottom();

    // Queue in local DB for durability (survives app restart / offline)
    _messageRepository.queueMessage(
      localId: tempId,
      conversationId: conversation.id,
      senderId: currentUserId,
      senderName: _authService.currentUser?.name,
      type: MessageType.text.value,
      content: text,
      replyToId: message.replyToMessageId,
      replyToContent: message.replyToContent,
      replyToSenderName: message.replyToSenderName,
    );

    // Send via socket (queued automatically if not connected yet)
    _socketService.sendMessage(
      conversationId: conversation.id,
      type: MessageType.text.value,
      localId: tempId,
      content: text,
      replyToId: message.replyToMessageId,
    );
  }

  void sendMediaMessage(MediaAttachmentModel attachment) {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final message = MessageModel(
      id: tempId,
      conversationId: conversation.id,
      senderId: currentUserId,
      senderName: _authService.currentUser?.name,
      type: attachment.mediaType,
      content: attachment.fileName,
      attachment: attachment,
      status: MessageStatusType.sending,
      replyToMessageId: replyingTo.value?.id,
      replyToContent: replyingTo.value?.content,
      replyToSenderName: replyingTo.value?.senderName,
      createdAt: DateTime.now(),
    );

    messages.insert(0, message);
    cancelReply();
    _scrollToBottom();

    // Queue in local DB for durability
    _messageRepository.queueMessage(
      localId: tempId,
      conversationId: conversation.id,
      senderId: currentUserId,
      senderName: _authService.currentUser?.name,
      type: attachment.mediaType.value,
      content: attachment.fileName,
      mediaId: attachment.id,
      replyToId: message.replyToMessageId,
      replyToContent: message.replyToContent,
      replyToSenderName: message.replyToSenderName,
    );

    // Send via socket (queued automatically if not connected yet)
    _socketService.sendMessage(
      conversationId: conversation.id,
      type: attachment.mediaType.value,
      localId: tempId,
      content: attachment.fileName,
      mediaId: attachment.id,
      replyToId: message.replyToMessageId,
    );
  }

  // ── Message Actions ────────────────────────────────────────────────────

  void deleteMessage(String messageId, {bool forEveryone = false}) {
    // Send delete via socket
    _socketService.deleteMessage(
      conversationId: conversation.id,
      messageId: messageId,
      forEveryone: forEveryone,
    );

    // Optimistic UI update
    if (forEveryone) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(isDeleted: true);
      }
    } else {
      messages.removeWhere((m) => m.id == messageId);
    }
  }

  void setReplyTo(MessageModel message) {
    replyingTo.value = message;
  }

  void cancelReply() {
    replyingTo.value = null;
  }

  /// Shows a bottom sheet with the list of users who have read a message.
  /// Only used for group chats — fetches readers from the server API.
  Future<void> showMessageReaders(String messageId) async {
    try {
      final response = await _messageRepository.getMessageReaders(
        conversationId: conversation.id,
        messageId: messageId,
      );
      if (response.isSuccessful && response.data != null) {
        final rawData = response.data;
        final List readers = rawData is Map
            ? (rawData['data'] as List? ?? [])
            : (rawData as List);
        _showReadersSheet(readers);
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error fetching readers: $e');
    }
  }

  void _showReadersSheet(List readers) {
    final context = Get.context;
    if (context == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ChatColors.getInstance(ctx);
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colors.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${Keys.Read_by.tr} (${readers.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (readers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      Keys.No_one_has_read.tr,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  )
                else
                  ...readers.map((r) {
                    final name =
                        (r['fullName'] ?? r['full_name'] ?? '') as String;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            colors.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(color: colors.primaryColor),
                        ),
                      ),
                      title: Text(name,
                          style: TextStyle(color: colors.textPrimary)),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Search ──────────────────────────────────────────────────────────

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchResults.clear();
      isSearchLoading.value = false;
      _searchDebounce?.cancel();
    }
  }

  void onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      searchResults.clear();
      isSearchLoading.value = false;
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchMessages(query.trim());
    });
  }

  Future<void> _searchMessages(String query) async {
    try {
      isSearchLoading.value = true;
      final response = await _messageRepository.searchMessages(
        conversationId: conversation.id,
        query: query,
      );
      if (response.isSuccessful && response.data != null) {
        final rawData = response.data;
        final List results = rawData is Map
            ? (rawData['data'] as List? ?? [])
            : (rawData as List);
        searchResults.value = results
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error searching messages: $e');
    } finally {
      isSearchLoading.value = false;
    }
  }

  // ── Jump to Message (search result tap + reply redirect) ────────────

  /// Scrolls to a message by ID. If the message is already loaded, scrolls
  /// instantly. If not, fetches messages around it from the server.
  /// Used by both search result taps and reply-tap navigation.
  Future<bool> scrollToMessage(String messageId) async {
    // Fast path: message already in memory
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _scrollToIndex(index);
      _highlightMessage(messageId);
      return true;
    }

    // Slow path: fetch from server
    return await _jumpToMessage(messageId);
  }

  Future<bool> _jumpToMessage(String messageId) async {
    try {
      final response = await _messageRepository.getMessagesAround(
        conversationId: conversation.id,
        messageId: messageId,
      );

      if (!response.isSuccessful || response.data == null) return false;

      final rawData = response.data as Map<String, dynamic>;
      final List messageList = rawData['data'] as List? ?? [];
      final targetIndex = rawData['targetIndex'] as int? ?? 0;
      final hasOlder = rawData['hasOlder'] as bool? ?? false;

      final parsedMessages = messageList
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (parsedMessages.isEmpty) return false;

      // Replace the message list with the "around" data
      messages.value = parsedMessages;
      hasMoreMessages.value = hasOlder;
      isViewingOldMessages.value = true;

      // Reset cursor for continued backward pagination from the oldest message
      _nextCursor = null; // Will be rebuilt on next loadMore

      // Wait for the list to build, then scroll + highlight
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToIndex(targetIndex);
      _highlightMessage(messageId);

      return true;
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error jumping to message: $e');
      return false;
    }
  }

  void _scrollToIndex(int index) {
    if (itemScrollController.isAttached) {
      itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  void _highlightMessage(String messageId) {
    highlightedMessageId.value = messageId;
    Future.delayed(const Duration(seconds: 2), () {
      if (highlightedMessageId.value == messageId) {
        highlightedMessageId.value = null;
      }
    });
  }

  /// Returns to the latest messages (called from scroll-to-bottom FAB
  /// when viewing old messages after a jump).
  void returnToLatestMessages() {
    isViewingOldMessages.value = false;
    _nextCursor = null;
    hasMoreMessages.value = true;
    loadMessages();
  }

  // ── Socket Listeners ──────────────────────────────────────────────────

  void _setupSocketListeners() {
    // Server emits 'message:new' with { id, conversationId, senderId, senderName, type, content, ... }
    _newMessageSub = _socketService.onNewMessage.listen((message) {
      if (message.conversationId != conversation.id) return;
      // Avoid duplicates from optimistic inserts
      if (messages.any((m) => m.id == message.id)) return;

      messages.insert(0, message);
      _scrollToBottom();

      // Persist incoming message to local cache
      _messageRepository.cacheMessage(message);

      // Mark as delivered and read since user is viewing this conversation
      _socketService.markAsDelivered(conversation.id, message.id);
      _socketService.markAsRead(conversation.id, message.id);
    });

    // Server emits 'message:sent' with { localId, messageId, createdAt }
    // This confirms our socket-sent message was processed.
    // Update the temp message ID to the server-generated ID and mark as sent.
    _messageSentSub = _socketService.onMessageSent.listen((data) {
      final localId = data['localId'] as String?;
      final messageId = data['messageId'] as String?;
      final createdAtStr = data['createdAt'] as String?;
      if (localId == null || messageId == null) return;

      final index = messages.indexWhere((m) => m.id == localId);
      if (index != -1) {
        final confirmedMessage = messages[index].copyWith(
          id: messageId,
          status: MessageStatusType.sent,
          createdAt: createdAtStr != null
              ? DateTime.tryParse(createdAtStr)
              : null,
        );
        messages[index] = confirmedMessage;

        // Move from pending queue to messages cache
        _messageRepository.markPendingAsSent(
            localId, messageId, confirmedMessage);
      }
    });

    // Server emits 'message:delivered:ack' with { messageId, conversationId, userId, timestamp }
    _messageDeliveredSub =
        _socketService.onMessageDelivered.listen((data) {
      final convId = data['conversationId'] as String?;
      if (convId != null && convId != conversation.id) return;
      final messageId = data['messageId'] as String?;
      if (messageId == null) return;
      _updateMessageStatus(messageId, MessageStatusType.delivered);
    });

    // Server emits 'message:read:ack' with { messageId, conversationId, userId, timestamp }
    _messageReadSub = _socketService.onMessageRead.listen((data) {
      final convId = data['conversationId'] as String?;
      if (convId != null && convId != conversation.id) return;
      final messageId = data['messageId'] as String?;
      if (messageId == null) return;
      _updateMessageStatus(messageId, MessageStatusType.read);
    });

    // Server emits 'message:deleted' with { messageId, conversationId, forEveryone }
    _messageDeletedSub = _socketService.onMessageDeleted.listen((data) {
      final convId = data['conversationId'] as String?;
      if (convId != conversation.id) return;

      final messageId = data['messageId'] as String?;
      final forEveryone = data['forEveryone'] as bool? ?? false;
      if (messageId == null) return;

      if (forEveryone) {
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          messages[index] = messages[index].copyWith(isDeleted: true);
        }
      }
    });

    // Server emits 'presence:update' with { userId, status, lastSeenAt }
    _presenceSub = _socketService.onPresenceUpdate.listen((data) {
      final userId = data['userId'] as String?;
      final status = data['status'] as String?;
      if (userId == null || status == null) return;

      // Update presence for the other participant in 1:1 conversations
      final other = otherParticipant;
      if (other != null && other.id == userId) {
        otherUserPresence.value = UserPresence.fromValue(status);
      }
    });

    // Server emits 'typing:indicator' with { conversationId, userId, userName, isTyping }
    _typingSub = _socketService.onTyping.listen((data) {
      final conversationId = data['conversationId'] as String?;
      if (conversationId != conversation.id) return;

      final userName = data['userName'] as String? ?? 'Someone';
      final isTyping = data['isTyping'] as bool? ?? true;

      if (isTyping) {
        if (!typingUsers.contains(userName)) {
          typingUsers.add(userName);
        }
        // Auto-remove after 5 seconds if no stop event
        Future.delayed(const Duration(seconds: 5), () {
          typingUsers.remove(userName);
        });
      } else {
        typingUsers.remove(userName);
      }
    });

    // Server emits 'conversation:updated' when conversation metadata changes
    // (e.g., group name, avatar). Update our local conversation object.
    _conversationUpdatedSub =
        _socketService.onConversationUpdated.listen((data) {
      final convId = data['conversationId'] as String? ?? data['id'] as String?;
      if (convId != conversation.id) return;

      // If the event contains full conversation data, update our copy
      if (data.containsKey('type') && data.containsKey('id')) {
        try {
          final updated = ConversationModel.fromJson(data);
          _conversation.value = updated.copyWith(
            lastMessage: conversation.lastMessage,
            lastMessageAt: conversation.lastMessageAt,
            unreadCount: conversation.unreadCount,
          );
        } catch (_) {}
      } else if (data.containsKey('name')) {
        // Lightweight update with just name
        _conversation.value =
            conversation.copyWith(name: data['name'] as String?);
      }
    });
  }

  // ── Typing Indicator ──────────────────────────────────────────────────

  void onTextChanged(String text) {
    messageText.value = text;

    if (text.isNotEmpty && !_isCurrentlyTyping) {
      _isCurrentlyTyping = true;
      _socketService.startTyping(conversation.id);
    }

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (_isCurrentlyTyping) {
        _isCurrentlyTyping = false;
        _socketService.stopTyping(conversation.id);
      }
    });

    if (text.isEmpty && _isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      _socketService.stopTyping(conversation.id);
      _typingDebounce?.cancel();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  bool isMyMessage(MessageModel msg) => msg.senderId == currentUserId;

  void _updateMessageStatus(String messageId, MessageStatusType status) {
    final targetIndex = messages.indexWhere((m) => m.id == messageId);
    if (targetIndex == -1) return;

    // For read/delivered receipts, update all own messages up to (and including)
    // the target message. In a reversed list, index 0 is newest. The target
    // message and all older own messages (higher indices) should be updated.
    if (status == MessageStatusType.read ||
        status == MessageStatusType.delivered) {
      for (int i = targetIndex; i < messages.length; i++) {
        final msg = messages[i];
        if (msg.senderId != currentUserId) continue;
        // Only upgrade status, never downgrade (e.g. don't go from read→delivered)
        // Skip failed messages — they need to be resent, not upgraded
        if (msg.status == MessageStatusType.failed) continue;
        if (_statusRank(msg.status) >= _statusRank(status)) continue;
        messages[i] = msg.copyWith(status: status);
      }
    } else {
      messages[targetIndex] =
          messages[targetIndex].copyWith(status: status);
    }
  }

  /// Returns a numeric rank for status comparison. Higher = more progressed.
  static int _statusRank(MessageStatusType status) {
    switch (status) {
      case MessageStatusType.sending:
        return 0;
      case MessageStatusType.sent:
        return 1;
      case MessageStatusType.delivered:
        return 2;
      case MessageStatusType.read:
        return 3;
      case MessageStatusType.failed:
        return -1;
    }
  }

  void _markAllAsRead() {
    if (messages.isNotEmpty) {
      final latestMessageId = messages.first.id;
      // Mark all messages as delivered first (in case some were missed while offline)
      _socketService.markAsDelivered(conversation.id, latestMessageId);
      // Then mark all as read since the user is viewing this conversation.
      // The server will reset unread_count=0 in the DB and emit
      // 'conversation:unread:update' back to this socket, which the
      // ChatListController listens to — so no manual clearing needed here.
      _socketService.markAsRead(conversation.id, latestMessageId);
    }
  }

  /// Scrolls to the newest message (index 0 in the reversed list).
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (itemScrollController.isAttached) {
        itemScrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Called when visible item positions change.
  /// Handles load-more pagination and scroll-to-bottom FAB visibility.
  void _onItemPositionsChanged() {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Load more when the last visible item is near the end of the list
    final maxIndex = positions.map((p) => p.index).reduce(
        (a, b) => a > b ? a : b);
    if (maxIndex >= messages.length - 5 && hasMoreMessages.value) {
      loadMoreMessages();
    }

    // Show scroll-to-bottom FAB when item 0 is NOT visible
    final minIndex = positions.map((p) => p.index).reduce(
        (a, b) => a < b ? a : b);
    showScrollToBottom.value = minIndex > 3;
  }

  /// Scrolls to the bottom of the chat (newest messages). Public for the FAB.
  /// If viewing old messages (after a jump), reloads the latest messages first.
  void scrollToBottom() {
    if (isViewingOldMessages.value) {
      returnToLatestMessages();
      return;
    }
    if (itemScrollController.isAttached) {
      itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Returns the other participant in a 1:1 conversation, or null.
  UserModel? get otherParticipant {
    if (isGroup || conversation.participants == null) return null;
    final others =
        conversation.participants!.where((p) => p.id != currentUserId);
    return others.isNotEmpty ? others.first : null;
  }
}
