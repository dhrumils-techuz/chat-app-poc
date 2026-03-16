import '../../../core/data/api_response_model.dart';
import '../service/chat/chat_remote_service.dart';

class ChatRepository {
  final ChatRemoteService _chatService;

  ChatRepository({required ChatRemoteService chatService})
      : _chatService = chatService;

  Future<ApiResponseModel> getConversations({
    int page = 1,
    int pageSize = 20,
    String? folderId,
  }) {
    return _chatService.getConversations(
      page: page,
      pageSize: pageSize,
      folderId: folderId,
    );
  }

  Future<ApiResponseModel> getConversationById(String conversationId) {
    return _chatService.getConversationById(conversationId);
  }

  Future<ApiResponseModel> createPrivateConversation(String userId) {
    return _chatService.createPrivateConversation(userId);
  }

  Future<ApiResponseModel> createGroupConversation({
    required String name,
    required List<String> memberIds,
    String? avatarUrl,
  }) {
    return _chatService.createGroupConversation(
      name: name,
      memberIds: memberIds,
      avatarUrl: avatarUrl,
    );
  }

  Future<ApiResponseModel> updateConversation({
    required String conversationId,
    String? name,
    String? avatarUrl,
  }) {
    return _chatService.updateConversation(
      conversationId: conversationId,
      name: name,
      avatarUrl: avatarUrl,
    );
  }

  Future<ApiResponseModel> deleteConversation(String conversationId) {
    return _chatService.deleteConversation(conversationId);
  }

  Future<ApiResponseModel> addMember({
    required String conversationId,
    required String userId,
  }) {
    return _chatService.addMember(
      conversationId: conversationId,
      userId: userId,
    );
  }

  Future<ApiResponseModel> removeMember({
    required String conversationId,
    required String userId,
  }) {
    return _chatService.removeMember(
      conversationId: conversationId,
      userId: userId,
    );
  }

  Future<ApiResponseModel> muteConversation({
    required String conversationId,
    required bool mute,
  }) {
    return _chatService.muteConversation(
      conversationId: conversationId,
      mute: mute,
    );
  }

  Future<ApiResponseModel> pinConversation({
    required String conversationId,
    required bool pin,
  }) {
    return _chatService.pinConversation(
      conversationId: conversationId,
      pin: pin,
    );
  }

  Future<ApiResponseModel> archiveConversation({
    required String conversationId,
    required bool archive,
  }) {
    return _chatService.archiveConversation(
      conversationId: conversationId,
      archive: archive,
    );
  }

  Future<ApiResponseModel> searchUsers(String query) {
    return _chatService.searchUsers(query);
  }
}
