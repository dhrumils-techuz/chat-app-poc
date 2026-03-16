import '../../../core/data/api_response_model.dart';
import '../service/message/message_remote_service.dart';

class MessageRepository {
  final MessageRemoteService _messageService;

  MessageRepository({required MessageRemoteService messageService})
      : _messageService = messageService;

  Future<ApiResponseModel> getMessages({
    required String conversationId,
    int limit = 50,
    String? cursor,
    String direction = 'forward',
  }) {
    return _messageService.getMessages(
      conversationId: conversationId,
      limit: limit,
      cursor: cursor,
      direction: direction,
    );
  }

  Future<ApiResponseModel> sendMessage({
    required String conversationId,
    required String content,
    required String type,
    String? replyToId,
    String? mediaId,
  }) {
    return _messageService.sendMessage(
      conversationId: conversationId,
      content: content,
      type: type,
      replyToId: replyToId,
      mediaId: mediaId,
    );
  }

  Future<ApiResponseModel> deleteMessage({
    required String conversationId,
    required String messageId,
    bool deleteForEveryone = false,
  }) {
    return _messageService.deleteMessage(
      conversationId: conversationId,
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
