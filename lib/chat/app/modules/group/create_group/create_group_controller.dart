import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/api_response_model.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/logs_helper.dart';
import '../../../data/model/conversation_model.dart';
import '../../../data/auth/jwt_auth_service.dart';
import '../../../data/model/user_model.dart';
import '../../../data/repository/chat_repository.dart';
import '../../../routes/app_pages.dart';
import '../../chat_list/chat_list_controller.dart';

class CreateGroupController extends GetxController {
  static const String _tag = 'CreateGroupController';

  final ChatRepository _chatRepository;
  final JwtAuthService _authService;

  CreateGroupController({
    required ChatRepository chatRepository,
    required JwtAuthService authService,
  })  : _chatRepository = chatRepository,
        _authService = authService;

  String get currentUserId => _authService.currentUserId ?? '';

  // Form controllers
  final groupNameController = TextEditingController();

  // Observable state
  final selectedMembers = <UserModel>[].obs;
  final searchResults = <UserModel>[].obs;
  final isLoading = false.obs;
  final isCreating = false.obs;
  final searchQuery = ''.obs;
  final groupName = ''.obs;

  // Debounce timer for search
  Timer? _debounceTimer;

  bool get isValid =>
      groupName.value.trim().isNotEmpty &&
      selectedMembers.length >= 2;

  @override
  void onInit() {
    super.onInit();
    // Sync TextEditingController with reactive groupName so Obx can track it
    groupNameController.addListener(() {
      groupName.value = groupNameController.text;
    });
  }

  @override
  void onClose() {
    groupNameController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }

  // ── Search ───────────────────────────────────────────────────────────

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      searchUsers(query.trim());
    });
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) return;
    try {
      isLoading.value = true;
      final ApiResponseModel response =
          await _chatRepository.searchUsers(query);
      if (response.isSuccessful && response.data != null) {
        final rawData = response.data;
        final List userData = rawData is Map
            ? (rawData['data'] as List? ?? [])
            : (rawData as List);
        final users = userData
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .where((u) => u.id != currentUserId)
            .toList();
        searchResults.value = users;
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error searching users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Member Selection ─────────────────────────────────────────────────

  void toggleMember(UserModel user) {
    final index = selectedMembers.indexWhere((m) => m.id == user.id);
    if (index != -1) {
      selectedMembers.removeAt(index);
    } else {
      selectedMembers.add(user);
    }
  }

  bool isMemberSelected(String userId) {
    return selectedMembers.any((m) => m.id == userId);
  }

  void removeMember(UserModel user) {
    selectedMembers.removeWhere((m) => m.id == user.id);
  }

  // ── Group Creation ───────────────────────────────────────────────────

  Future<void> createGroup() async {
    final name = groupNameController.text.trim();
    if (name.isEmpty) {
      DialogHelper.showSnackBar('Error', 'Please enter a group name');
      return;
    }
    if (selectedMembers.length < 2) {
      DialogHelper.showSnackBar(
          'Error', 'Please select at least 2 members');
      return;
    }

    try {
      isCreating.value = true;
      final memberIds = selectedMembers.map((m) => m.id).toList();
      final ApiResponseModel response =
          await _chatRepository.createGroupConversation(
        name: name,
        memberIds: memberIds,
      );

      if (response.isSuccessful && response.data != null) {
        final rawData = response.data;
        final convData = rawData is Map && rawData.containsKey('data')
            ? rawData['data'] as Map<String, dynamic>
            : rawData as Map<String, dynamic>;
        // Go back to chat list — the new group will appear via socket update.
        // The server emits 'conversation:new' to all participants including
        // the creator's other screens; the creator's own list is refreshed here.
        if (Get.isRegistered<ChatListController>()) {
          final listCtrl = Get.find<ChatListController>();
          final conversation = ConversationModel.fromJson(convData);
          if (!listCtrl.conversations.any((c) => c.id == conversation.id)) {
            listCtrl.conversations.add(conversation);
            listCtrl.refreshConversations();
          }
        }
        Get.until((route) =>
            route.settings.name == ChatAppRoutes.CHAT_LIST);
      } else {
        DialogHelper.showSnackBar(
          'Error',
          response.message ?? 'Failed to create group',
        );
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error creating group: $e');
      DialogHelper.showSnackBar('Error', 'Failed to create group');
    } finally {
      isCreating.value = false;
    }
  }
}
