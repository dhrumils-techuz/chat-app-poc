import '../../../../core/data/api_response_model.dart';

abstract class MessageRemoteService {
  Future<ApiResponseModel> getMessages({
    required String conversationId,
    int limit = 50,
    String? cursor,
    String direction = 'forward',
  });

  Future<ApiResponseModel> sendMessage({
    required String conversationId,
    required String content,
    required String type,
    String? replyToId,
    String? mediaId,
  });

  Future<ApiResponseModel> deleteMessage({
    required String conversationId,
    required String messageId,
    bool deleteForEveryone = false,
  });

  Future<ApiResponseModel> markAsRead(String conversationId);

  Future<ApiResponseModel> markAsDelivered(String conversationId);

  Future<ApiResponseModel> getMessageReaders({
    required String conversationId,
    required String messageId,
  });

  Future<ApiResponseModel> searchMessages({
    required String conversationId,
    required String query,
    int limit = 20,
  });

  Future<ApiResponseModel> getMessagesAround({
    required String conversationId,
    required String messageId,
    int limit = 50,
  });
}
