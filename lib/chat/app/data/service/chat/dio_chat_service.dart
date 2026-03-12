import 'dart:convert';

import '../../../../core/data/api_response_model.dart';
import '../../../../core/extension/dio_extensions.dart';
import '../../../../core/values/constants/server_endpoints.dart';
import '../../client/dio_remote_api_client.dart';
import 'chat_remote_service.dart';

class DioChatService implements ChatRemoteService {
  final DioRemoteApiClient _dioClient;

  DioChatService({required DioRemoteApiClient dioClient})
      : _dioClient = dioClient;

  // Conversations

  @override
  Future<ApiResponseModel> getConversations({
    int page = 1,
    int pageSize = 20,
    String? folderId,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.get(
        ApiEndpoints.conversations,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (folderId != null) 'folderId': folderId,
        },
      ),
    );
  }

  @override
  Future<ApiResponseModel> getConversationById(String conversationId) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.get(
        ApiEndpoints.conversationById(conversationId),
      ),
    );
  }

  @override
  Future<ApiResponseModel> createPrivateConversation(String userId) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.createConversation,
        data: json.encode({
          'type': 'private',
          'participantId': userId,
        }),
      ),
    );
  }

  @override
  Future<ApiResponseModel> createGroupConversation({
    required String name,
    required List<String> memberIds,
    String? avatarUrl,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.createGroup,
        data: json.encode({
          'name': name,
          'memberIds': memberIds,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        }),
      ),
    );
  }

  @override
  Future<ApiResponseModel> updateConversation({
    required String conversationId,
    String? name,
    String? avatarUrl,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.put(
        ApiEndpoints.conversationById(conversationId),
        data: json.encode({
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        }),
      ),
    );
  }

  @override
  Future<ApiResponseModel> deleteConversation(String conversationId) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.delete(
        ApiEndpoints.conversationById(conversationId),
      ),
    );
  }

  // Members

  @override
  Future<ApiResponseModel> addMember({
    required String conversationId,
    required String userId,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.addMember(conversationId),
        data: json.encode({'userId': userId}),
      ),
    );
  }

  @override
  Future<ApiResponseModel> removeMember({
    required String conversationId,
    required String userId,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.delete(
        ApiEndpoints.removeMember(conversationId, userId),
      ),
    );
  }

  // Conversation actions

  @override
  Future<ApiResponseModel> muteConversation({
    required String conversationId,
    required bool mute,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.put(
        ApiEndpoints.muteConversation(conversationId),
        data: json.encode({'mute': mute}),
      ),
    );
  }

  @override
  Future<ApiResponseModel> pinConversation({
    required String conversationId,
    required bool pin,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.put(
        ApiEndpoints.pinConversation(conversationId),
        data: json.encode({'pin': pin}),
      ),
    );
  }

  @override
  Future<ApiResponseModel> archiveConversation({
    required String conversationId,
    required bool archive,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.put(
        ApiEndpoints.archiveConversation(conversationId),
        data: json.encode({'archive': archive}),
      ),
    );
  }

  // Users

  @override
  Future<ApiResponseModel> searchUsers(String query) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.get(
        ApiEndpoints.searchUsers,
        queryParameters: {'q': query},
      ),
    );
  }

  // Folders

  @override
  Future<ApiResponseModel> getFolders() async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.get(ApiEndpoints.folders),
    );
  }

  @override
  Future<ApiResponseModel> createFolder({
    required String name,
    List<String>? conversationIds,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.folders,
        data: json.encode({
          'name': name,
          if (conversationIds != null) 'conversationIds': conversationIds,
        }),
      ),
    );
  }

  @override
  Future<ApiResponseModel> updateFolder({
    required String folderId,
    String? name,
    List<String>? conversationIds,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.put(
        ApiEndpoints.folderById(folderId),
        data: json.encode({
          if (name != null) 'name': name,
          if (conversationIds != null) 'conversationIds': conversationIds,
        }),
      ),
    );
  }

  @override
  Future<ApiResponseModel> deleteFolder(String folderId) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.delete(
        ApiEndpoints.folderById(folderId),
      ),
    );
  }

  @override
  Future<ApiResponseModel> addConversationToFolder({
    required String folderId,
    required String conversationId,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.folderConversations(folderId),
        data: json.encode({'conversationId': conversationId}),
      ),
    );
  }

  @override
  Future<ApiResponseModel> removeConversationFromFolder({
    required String folderId,
    required String conversationId,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.delete(
        '${ApiEndpoints.folderConversations(folderId)}/$conversationId',
      ),
    );
  }
}
