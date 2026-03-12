import 'package:get/get.dart';

import '../../../core/data/api_response_model.dart';
import '../../../core/utils/logs_helper.dart';
import '../../data/model/user_model.dart';
import '../../data/repository/chat_repository.dart';
import '../../routes/app_pages.dart';

class ContactsController extends GetxController {
  static const String _tag = 'ContactsController';

  final ChatRepository _chatRepository;

  ContactsController({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  final contacts = <UserModel>[].obs;
  final searchResults = <UserModel>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(searchQuery, (_) => searchContacts(), time: const Duration(milliseconds: 300));
  }

  Future<void> searchContacts() async {
    final query = searchQuery.value.trim();
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isLoading.value = true;
      final ApiResponseModel response = await _chatRepository.searchUsers(query);

      if (response.isSuccessful && response.data != null) {
        final users = (response.data as List)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();
        searchResults.value = users;
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error searching contacts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startConversation(UserModel user) async {
    try {
      isLoading.value = true;
      final response = await _chatRepository.createPrivateConversation(user.id);

      if (response.isSuccessful && response.data != null) {
        Get.offNamed(ChatAppRoutes.CHAT_DETAIL, arguments: response.data);
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error starting conversation: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }
}
