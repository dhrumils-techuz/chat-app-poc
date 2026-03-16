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

  // ── Controllers ────────────────────────────────────────────────────────
  final textController = TextEditingController();
  final scrollController = ScrollController();

  // ── Stream Subscriptions ───────────────────────────────────────────────
  StreamSubscription<MessageModel>? _newMessageSub;
  StreamSubscription<Map<String, dynamic>>? _messageSentSub;
  StreamSubscription<Map<String, dynamic>>? _messageDeliveredSub;
  StreamSubscription<Map<String, dynamic>>? _messageReadSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;

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
    _socketService.joinConversation(conversation.id);
    loadMessages();
    _setupSocketListeners();
    _markAllAsRead();
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
    _typingDebounce?.cancel();
    textController.dispose();
    scrollController.dispose();
    if (_isCurrentlyTyping) {
      _socketService.stopTyping(conversation.id);
    }
    super.onClose();
  }

  // ── Data Loading ───────────────────────────────────────────────────────

  Future<void> loadMessages({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        isLoading.value = true;
        _nextCursor = null;
      }

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
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error loading messages: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
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

    // Send via socket with the format the server expects:
    //   { conversationId, type, content?, mediaId?, replyToId?, localId }
    _socketService.sendMessage(
      conversationId: conversation.id,
      type: MessageType.text.value,
      localId: tempId,
      content: text,
      replyToId: message.replyToMessageId,
    );

    // Also send via REST for persistence
    _messageRepository.sendMessage(
      conversationId: conversation.id,
      content: text,
      type: MessageType.text.value,
      replyToId: message.replyToMessageId,
    ).then((response) {
      if (response.isSuccessful && response.data != null) {
        final rawData = response.data;
        final messageData = rawData is Map && rawData.containsKey('data')
            ? rawData['data'] as Map<String, dynamic>
            : rawData as Map<String, dynamic>;
        final serverMessage = MessageModel.fromJson(messageData);
        final index = messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          messages[index] = serverMessage;
        }
      } else {
        _updateMessageStatus(tempId, MessageStatusType.failed);
      }
    }).catchError((e) {
      LogsHelper.debugLog(tag: _tag, 'Error sending message: $e');
      _updateMessageStatus(tempId, MessageStatusType.failed);
    });
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

    // Send via REST (media messages need mediaId from upload)
    _messageRepository.sendMessage(
      conversationId: conversation.id,
      content: attachment.fileName,
      type: attachment.mediaType.value,
      replyToId: message.replyToMessageId,
      mediaId: attachment.id,
    ).then((response) {
      if (response.isSuccessful && response.data != null) {
        final rawData = response.data;
        final messageData = rawData is Map && rawData.containsKey('data')
            ? rawData['data'] as Map<String, dynamic>
            : rawData as Map<String, dynamic>;
        final serverMessage = MessageModel.fromJson(messageData);
        final index = messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          messages[index] = serverMessage;
        }
      } else {
        _updateMessageStatus(tempId, MessageStatusType.failed);
      }
    }).catchError((e) {
      LogsHelper.debugLog(tag: _tag, 'Error sending media message: $e');
      _updateMessageStatus(tempId, MessageStatusType.failed);
    });
  }

  // ── Message Actions ────────────────────────────────────────────────────

  void deleteMessage(String messageId, {bool forEveryone = false}) {
    _messageRepository.deleteMessage(
      conversationId: conversation.id,
      messageId: messageId,
      deleteForEveryone: forEveryone,
    );

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

  // ── Socket Listeners ──────────────────────────────────────────────────

  void _setupSocketListeners() {
    // Server emits 'message:new' with { id, conversationId, senderId, senderName, type, content, ... }
    _newMessageSub = _socketService.onNewMessage.listen((message) {
      if (message.conversationId != conversation.id) return;
      // Avoid duplicates from optimistic inserts
      if (messages.any((m) => m.id == message.id)) return;

      messages.insert(0, message);
      _scrollToBottom();

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
        messages[index] = messages[index].copyWith(
          id: messageId,
          status: MessageStatusType.sent,
          createdAt: createdAtStr != null
              ? DateTime.tryParse(createdAtStr)
              : null,
        );
      }
    });

    // Server emits 'message:delivered:ack' with { messageId, userId, timestamp }
    _messageDeliveredSub =
        _socketService.onMessageDelivered.listen((data) {
      final messageId = data['messageId'] as String?;
      if (messageId == null) return;
      _updateMessageStatus(messageId, MessageStatusType.delivered);
    });

    // Server emits 'message:read:ack' with { messageId, userId, timestamp }
    _messageReadSub = _socketService.onMessageRead.listen((data) {
      final messageId = data['messageId'] as String?;
      if (messageId == null) return;
      // Update that specific message (or all own messages up to that point)
      _updateMessageStatus(messageId, MessageStatusType.read);
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
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      messages[index] = messages[index].copyWith(status: status);
    }
  }

  void _markAllAsRead() {
    _messageRepository.markAsRead(conversation.id);
    if (messages.isNotEmpty) {
      _socketService.markAsRead(conversation.id, messages.first.id);
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
