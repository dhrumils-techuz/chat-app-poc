import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/api_response_model.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/logs_helper.dart';
import '../../../data/auth/jwt_auth_service.dart';
import '../../../data/model/conversation_model.dart';
import '../../../data/model/group_member_model.dart';
import '../../../data/model/user_model.dart';
import '../../../data/repository/chat_repository.dart';
import '../../../routes/app_pages.dart';

class GroupInfoController extends GetxController {
  static const String _tag = 'GroupInfoController';

  final ChatRepository _chatRepository;
  final JwtAuthService _authService;

  GroupInfoController({
    required ChatRepository chatRepository,
    required JwtAuthService authService,
  })  : _chatRepository = chatRepository,
        _authService = authService;

  // Observable state
  late final Rx<ConversationModel> conversation;
  final members = <GroupMemberModel>[].obs;
  final isLoading = false.obs;
  final isEditingName = false.obs;
  final groupNameController = TextEditingController();

  String get currentUserId => _authService.currentUserId ?? '';
  ChatRepository get chatRepository => _chatRepository;

  bool get isAdmin {
    return members.any(
      (m) => m.userId == currentUserId && m.isAdmin,
    );
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is ConversationModel) {
      conversation = Rx<ConversationModel>(args);
      groupNameController.text = args.displayName;
      _loadMembers();
    }
  }

  @override
  void onClose() {
    groupNameController.dispose();
    super.onClose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────

  void _loadMembers() {
    if (conversation.value.groupMembers != null) {
      members.value = List.from(conversation.value.groupMembers!);
    }
    loadGroupInfo();
  }

  Future<void> loadGroupInfo() async {
    try {
      isLoading.value = true;
      final ApiResponseModel response =
          await _chatRepository.getConversationById(conversation.value.id);

      if (response.isSuccessful && response.data != null) {
        final updated = ConversationModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        conversation.value = updated;
        if (updated.groupMembers != null) {
          members.value = List.from(updated.groupMembers!);
        }
        groupNameController.text = updated.displayName;
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error loading group info: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Group Name Editing ────────────────────────────────────────────────

  void toggleEditName() {
    if (isEditingName.value) {
      updateGroupName();
    } else {
      isEditingName.value = true;
    }
  }

  Future<void> updateGroupName() async {
    final newName = groupNameController.text.trim();
    if (newName.isEmpty) {
      DialogHelper.showSnackBar('Error', 'Group name cannot be empty');
      return;
    }

    try {
      final ApiResponseModel response =
          await _chatRepository.updateConversation(
        conversationId: conversation.value.id,
        name: newName,
      );
      if (response.isSuccessful) {
        conversation.value = conversation.value.copyWith(name: newName);
        isEditingName.value = false;
        DialogHelper.showSnackBar('Success', 'Group name updated');
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error updating group name: $e');
      DialogHelper.showSnackBar('Error', 'Failed to update group name');
    }
  }

  // ── Member Management ─────────────────────────────────────────────────

  Future<void> addMember(UserModel user) async {
    try {
      final ApiResponseModel response = await _chatRepository.addMember(
        conversationId: conversation.value.id,
        userId: user.id,
      );
      if (response.isSuccessful) {
        final newMember = GroupMemberModel(
          userId: user.id,
          name: user.name,
          avatarUrl: user.avatarUrl,
          role: GroupRole.member,
          joinedAt: DateTime.now(),
        );
        members.add(newMember);
        DialogHelper.showSnackBar('Success', '${user.name} added to group');
      }
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Error adding member: $e');
      DialogHelper.showSnackBar('Error', 'Failed to add member');
    }
  }

  Future<void> removeMember(GroupMemberModel member) async {
    DialogHelper.showConfirmationDialog(
      'Remove Member',
      'Are you sure you want to remove ${member.name} from the group?',
      btnPositiveText: 'Remove',
      btnNegativeText: 'Cancel',
      onPositiveResponse: () async {
        try {
          final ApiResponseModel response =
              await _chatRepository.removeMember(
            conversationId: conversation.value.id,
            userId: member.userId,
          );
          if (response.isSuccessful) {
            members.removeWhere((m) => m.userId == member.userId);
            DialogHelper.showSnackBar(
                'Success', '${member.name} removed from group');
          }
        } catch (e) {
          LogsHelper.debugLog(tag: _tag, 'Error removing member: $e');
          DialogHelper.showSnackBar('Error', 'Failed to remove member');
        }
      },
    );
  }

  // ── Leave Group ───────────────────────────────────────────────────────

  void leaveGroup() {
    DialogHelper.showConfirmationDialog(
      'Leave Group',
      'Are you sure you want to leave this group?',
      btnPositiveText: 'Leave',
      btnNegativeText: 'Cancel',
      onPositiveResponse: () async {
        try {
          final ApiResponseModel response =
              await _chatRepository.removeMember(
            conversationId: conversation.value.id,
            userId: currentUserId,
          );
          if (response.isSuccessful) {
            Get.until(
              (route) => route.settings.name == ChatAppRoutes.CHAT_LIST,
            );
          }
        } catch (e) {
          LogsHelper.debugLog(tag: _tag, 'Error leaving group: $e');
          DialogHelper.showSnackBar('Error', 'Failed to leave group');
        }
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  List<String> get memberUserIds => members.map((m) => m.userId).toList();
}
