import '../../../../core/data/api_response_model.dart';

abstract class MessageRemoteService {
  Future<ApiResponseModel> getMessages({
    required String conversationId,
    int page = 1,
    int pageSize = 50,
    String? beforeMessageId,
  });

  Future<ApiResponseModel> sendMessage({
    required String conversationId,
    required String content,
    required String type,
    String? replyToMessageId,
    Map<String, dynamic>? attachment,
  });

  Future<ApiResponseModel> deleteMessage({
    required String messageId,
    bool deleteForEveryone = false,
  });

  Future<ApiResponseModel> markAsRead(String conversationId);

  Future<ApiResponseModel> markAsDelivered(String conversationId);
}
