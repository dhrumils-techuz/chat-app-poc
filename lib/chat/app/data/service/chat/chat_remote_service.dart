import '../../../../core/data/api_response_model.dart';

abstract class ChatRemoteService {
  // Conversations
  Future<ApiResponseModel> getConversations({
    int page = 1,
    int pageSize = 20,
    String? folderId,
  });

  Future<ApiResponseModel> getConversationById(String conversationId);

  Future<ApiResponseModel> createPrivateConversation(String userId);

  Future<ApiResponseModel> createGroupConversation({
    required String name,
    required List<String> memberIds,
    String? avatarUrl,
  });

  Future<ApiResponseModel> updateConversation({
    required String conversationId,
    String? name,
    String? avatarUrl,
  });

  Future<ApiResponseModel> deleteConversation(String conversationId);

  // Members
  Future<ApiResponseModel> addMember({
    required String conversationId,
    required String userId,
  });

  Future<ApiResponseModel> removeMember({
    required String conversationId,
    required String userId,
  });

  // Conversation actions
  Future<ApiResponseModel> muteConversation({
    required String conversationId,
    required bool mute,
  });

  Future<ApiResponseModel> pinConversation({
    required String conversationId,
    required bool pin,
  });

  Future<ApiResponseModel> archiveConversation({
    required String conversationId,
    required bool archive,
  });

  // Users
  Future<ApiResponseModel> searchUsers(String query);

  // Folders
  Future<ApiResponseModel> getFolders();

  Future<ApiResponseModel> createFolder({
    required String name,
    List<String>? conversationIds,
  });

  Future<ApiResponseModel> updateFolder({
    required String folderId,
    String? name,
    List<String>? conversationIds,
  });

  Future<ApiResponseModel> deleteFolder(String folderId);

  Future<ApiResponseModel> addConversationToFolder({
    required String folderId,
    required String conversationId,
  });

  Future<ApiResponseModel> removeConversationFromFolder({
    required String folderId,
    required String conversationId,
  });
}
