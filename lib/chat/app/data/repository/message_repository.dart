import '../../../core/data/api_response_model.dart';
import '../service/message/message_remote_service.dart';

class MessageRepository {
  final MessageRemoteService _messageService;

  MessageRepository({required MessageRemoteService messageService})
      : _messageService = messageService;

  Future<ApiResponseModel> getMessages({
    required String conversationId,
    int page = 1,
    int pageSize = 50,
    String? beforeMessageId,
  }) {
    return _messageService.getMessages(
      conversationId: conversationId,
      page: page,
      pageSize: pageSize,
      beforeMessageId: beforeMessageId,
    );
  }

  Future<ApiResponseModel> sendMessage({
    required String conversationId,
    required String content,
    required String type,
    String? replyToMessageId,
    Map<String, dynamic>? attachment,
  }) {
    return _messageService.sendMessage(
      conversationId: conversationId,
      content: content,
      type: type,
      replyToMessageId: replyToMessageId,
      attachment: attachment,
    );
  }

  Future<ApiResponseModel> deleteMessage({
    required String messageId,
    bool deleteForEveryone = false,
  }) {
    return _messageService.deleteMessage(
      messageId: messageId,
      deleteForEveryone: deleteForEveryone,
    );
  }

  Future<ApiResponseModel> markAsRead(String conversationId) {
    return _messageService.markAsRead(conversationId);
  }

  Future<ApiResponseModel> markAsDelivered(String conversationId) {
    return _messageService.markAsDelivered(conversationId);
  }
}
