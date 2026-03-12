import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/api_response_model.dart';
import '../../../core/data/paginated_response.dart';
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

  ChatDetailController({
    required MessageRepository messageRepository,
    required SocketService socketService,
    required JwtAuthService authService,
  })  : _messageRepository = messageRepository,
        _socketService = socketService,
        _authService = authService;

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
  StreamSubscription<Map<String, dynamic>>? _messageDeliveredSub;
  StreamSubscription<Map<String, dynamic>>? _messageReadSub;
  StreamSubscription<String>? _messageDeletedSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;

  // ── Typing Debounce ────────────────────────────────────────────────────
  Timer? _typingDebounce;
  bool _isCurrentlyTyping = false;

  // ── Pagination ─────────────────────────────────────────────────────────
  int _currentPage = 1;
  static const int _pageSize = 50;

  // ── Computed Properties ────────────────────────────────────────────────
  String get currentUserId => _authService.currentUserId ?? '';
  bool get isGroup => conversation.isGroup;

  @override
  void onInit() {
    super.onInit();
    conversation = Get.arguments as ConversationModel;
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
    _messageDeliveredSub?.cancel();
    _messageReadSub?.cancel();
    _messageDeletedSub?.cancel();
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

  Future<void> loadMessages({String? beforeMessageId}) async {
    try {
      if (beforeMessageId == null) {
        isLoading.value = true;
        _currentPage = 1;
      }

      final ApiResponseModel response = await _messageRepository.getMessages(
        conversationId: conversation.id,
        page: _currentPage,
        pageSize: _pageSize,
        beforeMessageId: beforeMessageId,
      );

      if (response.isSuccessful && response.data != null) {
        final paginated = PaginatedResponse<MessageModel>.fromJson(
          response.data as Map<String, dynamic>,
          (json) => MessageModel.fromJson(json),
        );

        if (beforeMessageId != null) {
          messages.addAll(paginated.items);
        } else {
          messages.value = paginated.items;
        }
        hasMoreMessages.value = paginated.hasMore;
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
    _currentPage++;

    final String? lastMessageId =
        messages.isNotEmpty ? messages.last.id : null;
    await loadMessages(beforeMessageId: lastMessageId);
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

    // Send via socket
    _socketService.sendMessage(message.toJson());

    // Also send via REST for persistence
    _messageRepository.sendMessage(
      conversationId: conversation.id,
      content: text,
      type: MessageType.text.value,
      replyToMessageId: message.replyToMessageId,
    ).then((response) {
      if (response.isSuccessful && response.data != null) {
        final serverMessage = MessageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
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

    _messageRepository.sendMessage(
      conversationId: conversation.id,
      content: attachment.fileName,
      type: attachment.mediaType.value,
      replyToMessageId: message.replyToMessageId,
      attachment: attachment.toJson(),
    ).then((response) {
      if (response.isSuccessful && response.data != null) {
        final serverMessage = MessageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
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
    _newMessageSub = _socketService.onNewMessage.listen((message) {
      if (message.conversationId != conversation.id) return;
      // Avoid duplicates from optimistic inserts
      if (messages.any((m) => m.id == message.id)) return;

      messages.insert(0, message);
      _scrollToBottom();

      // Mark as delivered
      _socketService.markAsDelivered(conversation.id, message.id);
      _socketService.markAsRead(conversation.id, message.id);
    });

    _messageDeliveredSub =
        _socketService.onMessageDelivered.listen((data) {
      final messageId = data['messageId'] as String?;
      if (messageId == null) return;
      _updateMessageStatus(messageId, MessageStatusType.delivered);
    });

    _messageReadSub = _socketService.onMessageRead.listen((data) {
      final messageId = data['messageId'] as String?;
      final conversationId = data['conversationId'] as String?;
      if (conversationId != null && conversationId == conversation.id) {
        // Mark all messages as read
        for (int i = 0; i < messages.length; i++) {
          if (messages[i].senderId == currentUserId &&
              messages[i].status != MessageStatusType.read) {
            messages[i] = messages[i].copyWith(status: MessageStatusType.read);
          }
        }
      } else if (messageId != null) {
        _updateMessageStatus(messageId, MessageStatusType.read);
      }
    });

    _messageDeletedSub = _socketService.onMessageDeleted.listen((messageId) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(isDeleted: true);
      }
    });

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
