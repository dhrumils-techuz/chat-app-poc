import '../../../core/data/api_response_model.dart';
import '../../../core/data/paginated_response.dart';
import '../../../core/utils/logs_helper.dart';
import '../local/database/dao/conversation_dao.dart';
import '../local/database/dao/user_dao.dart';
import '../model/conversation_model.dart';
import '../service/chat/chat_remote_service.dart';

class ChatRepository {
  static const String _tag = 'ChatRepository';

  final ChatRemoteService _chatService;
  final ConversationDao _conversationDao;
  final UserDao _userDao;

  ChatRepository({
    required ChatRemoteService chatService,
    required ConversationDao conversationDao,
    required UserDao userDao,
  })  : _chatService = chatService,
        _conversationDao = conversationDao,
        _userDao = userDao;

  // ── Local-first reads ─────────────────────────────────────────────────

  /// Returns cached conversations from local DB.
  Future<List<ConversationModel>> getCachedConversations() async {
    return _conversationDao.getConversations();
  }

  /// Fetches conversations from remote, updates local cache, returns fresh data.
  Future<List<ConversationModel>> refreshConversations({
    int page = 1,
    int pageSize = 20,
    String? folderId,
  }) async {
    final response = await _chatService.getConversations(
      page: page,
      pageSize: pageSize,
      folderId: folderId,
    );

    if (response.isSuccessful && response.data != null) {
      final paginated = PaginatedResponse<ConversationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ConversationModel.fromJson(json),
      );
      final conversations = paginated.items;

      // Cache conversations and participants locally
      await _conversationDao.upsertConversations(conversations);
      for (final conv in conversations) {
        if (conv.participants != null && conv.participants!.isNotEmpty) {
          await _userDao.upsertUsers(conv.participants!);
        }
      }

      return conversations;
    }

    throw Exception('Failed to fetch conversations');
  }

  /// Updates local cache for a single conversation.
  Future<void> cacheConversation(ConversationModel conversation) async {
    await _conversationDao.upsertConversation(conversation);
  }

  // ── Remote-only operations ────────────────────────────────────────────

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
    _conversationDao.deleteConversation(conversationId);
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
    _conversationDao.updateMuteStatus(conversationId, mute);
    return _chatService.muteConversation(
      conversationId: conversationId,
      mute: mute,
    );
  }

  Future<ApiResponseModel> pinConversation({
    required String conversationId,
    required bool pin,
  }) {
    _conversationDao.updatePinStatus(conversationId, pin);
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
