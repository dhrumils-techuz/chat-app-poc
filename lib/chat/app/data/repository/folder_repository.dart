import '../../../core/data/api_response_model.dart';
import '../service/chat/chat_remote_service.dart';

class FolderRepository {
  final ChatRemoteService _chatService;

  FolderRepository({required ChatRemoteService chatService})
      : _chatService = chatService;

  Future<ApiResponseModel> getFolders() {
    return _chatService.getFolders();
  }

  Future<ApiResponseModel> createFolder({
    required String name,
    List<String>? conversationIds,
  }) {
    return _chatService.createFolder(
      name: name,
      conversationIds: conversationIds,
    );
  }

  Future<ApiResponseModel> updateFolder({
    required String folderId,
    String? name,
    List<String>? conversationIds,
  }) {
    return _chatService.updateFolder(
      folderId: folderId,
      name: name,
      conversationIds: conversationIds,
    );
  }

  Future<ApiResponseModel> deleteFolder(String folderId) {
    return _chatService.deleteFolder(folderId);
  }

  Future<ApiResponseModel> addConversationToFolder({
    required String folderId,
    required String conversationId,
  }) {
    return _chatService.addConversationToFolder(
      folderId: folderId,
      conversationId: conversationId,
    );
  }

  Future<ApiResponseModel> removeConversationFromFolder({
    required String folderId,
    required String conversationId,
  }) {
    return _chatService.removeConversationFromFolder(
      folderId: folderId,
      conversationId: conversationId,
    );
  }
}
