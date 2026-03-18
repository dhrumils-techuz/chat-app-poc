import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/api_response_model.dart';
import '../../../core/utils/logs_helper.dart';
import '../../data/auth/jwt_auth_service.dart';
import '../../data/model/conversation_model.dart';
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
  late final ConversationModel conversation;

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

  // ── Controllers ────────────────────────────────────────────────────────
  final textController = TextEditingController();
  final scrollController = ScrollController();

  /// GlobalKey map: messageId → GlobalKey, used for precise reply-tap scrolling.
  final Map<String, GlobalKey> messageKeys = {};

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
    conversation = _conversationOverride ?? Get.arguments as ConversationModel;
    // Initialize presence from participant data
    final other = otherParticipant;
    if (other != null) {
      otherUserPresence.value = other.presence;
    }
    _socketService.joinConversation(conversation.id);
    loadMessages(); // _markAllAsRead is called after messages load
    _setupSocketListeners();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    _socketService.leaveConversation(conversation.id);
    _newMessageSub?.cancel();
    _messageSentSub?.cancel();
    _messageDeliveredSub?.cancel();
    _messageReadSub?.cancel();
    _typingSub?.cancel();
    _messageDeletedSub?.cancel();
    _presenceSub?.cancel();
    _typingDebounce?.cancel();
    if (_isCurrentlyTyping) {
      _socketService.stopTyping(conversation.id);
    }
    // Defer disposal of UI controllers to the next frame so that the widget
    // tree has time to unmount first. This prevents "used after being disposed"
    // errors when switching conversations in tablet/desktop split-view mode.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      textController.dispose();
      scrollController.dispose();
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

  /// Returns (or creates) a GlobalKey for the given message ID.
  /// Used by the view layer to tag each message widget for precise scrolling.
  GlobalKey getKeyForMessage(String messageId) {
    return messageKeys.putIfAbsent(messageId, () => GlobalKey());
  }

  /// Scrolls to a specific message by ID (used for reply-tap navigation).
  /// Uses GlobalKey-based `Scrollable.ensureVisible` for precise positioning.
  /// Returns true if the message was found and scrolled to.
  bool scrollToMessage(String messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false;

    final key = messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.5, // Center the message in the viewport
      );
    } else {
      // Fallback: if the key isn't rendered yet, use estimated offset
      if (scrollController.hasClients) {
        final estimatedOffset = index * 72.0;
        scrollController.animateTo(
          estimatedOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }

    // Briefly highlight the message
    highlightedMessageId.value = messageId;
    Future.delayed(const Duration(seconds: 2), () {
      if (highlightedMessageId.value == messageId) {
        highlightedMessageId.value = null;
      }
    });

    return true;
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
      // Then mark all as read since the user is viewing this conversation
      _socketService.markAsRead(conversation.id, latestMessageId);
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _onScroll() {
    // Reversed list: reaching the "top" means scrolling to maxScrollExtent
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMoreMessages();
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
