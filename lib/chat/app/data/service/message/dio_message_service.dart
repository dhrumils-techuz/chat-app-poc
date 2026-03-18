import 'dart:convert';

import '../../../../core/data/api_response_model.dart';
import '../../../../core/extension/dio_extensions.dart';
import '../../../../core/values/constants/server_endpoints.dart';
import '../../client/dio_remote_api_client.dart';
import 'message_remote_service.dart';

class DioMessageService implements MessageRemoteService {
  final DioRemoteApiClient _dioClient;

  DioMessageService({required DioRemoteApiClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<ApiResponseModel> getMessages({
    required String conversationId,
    int limit = 50,
    String? cursor,
    String direction = 'forward',
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.get(
        ApiEndpoints.messagesByConversation(conversationId),
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
          'direction': direction,
        },
      ),
    );
  }

  @override
  Future<ApiResponseModel> sendMessage({
    required String conversationId,
    required String content,
    required String type,
    String? replyToId,
    String? mediaId,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.messagesByConversation(conversationId),
        data: json.encode({
          'content': content,
          'type': type,
          if (replyToId != null) 'replyToId': replyToId,
          if (mediaId != null) 'mediaId': mediaId,
        }),
      ),
    );
  }

  @override
  Future<ApiResponseModel> deleteMessage({
    required String conversationId,
    required String messageId,
    bool deleteForEveryone = false,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.delete(
        ApiEndpoints.deleteMessage(conversationId, messageId),
      ),
    );
  }

  @override
  Future<ApiResponseModel> markAsRead(String conversationId) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.markAsRead(conversationId),
      ),
      useDefaultErrorHandler: false,
    );
  }

  @override
  Future<ApiResponseModel> markAsDelivered(String conversationId) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.markAsDelivered(conversationId),
      ),
      useDefaultErrorHandler: false,
    );
  }

  @override
  Future<ApiResponseModel> getMessageReaders({
    required String conversationId,
    required String messageId,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.get(
        ApiEndpoints.messageReaders(conversationId, messageId),
      ),
      useDefaultErrorHandler: false,
    );
  }
}
