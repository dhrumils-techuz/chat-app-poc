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
import '../../../data/service/socket/socket_service.dart';
import '../../../routes/app_pages.dart';

class GroupInfoController extends GetxController {
  static const String _tag = 'GroupInfoController';

  final ChatRepository _chatRepository;
  final JwtAuthService _authService;
  final SocketService _socketService;

  GroupInfoController({
    required ChatRepository chatRepository,
    required JwtAuthService authService,
    required SocketService socketService,
  })  : _chatRepository = chatRepository,
        _authService = authService,
        _socketService = socketService;

  StreamSubscription<Map<String, dynamic>>? _conversationUpdatedSub;

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
      groupNameController.text = args.displayNameFor(currentUserId);
      _loadMembers();
    }
    _conversationUpdatedSub =
        _socketService.onConversationUpdated.listen(_handleConversationUpdated);
  }

  @override
  void onClose() {
    _conversationUpdatedSub?.cancel();
    groupNameController.dispose();
    super.onClose();
  }

  void _handleConversationUpdated(Map<String, dynamic> data) {
    final convId =
        data['conversationId'] as String? ?? data['id'] as String?;
    if (convId != conversation.value.id) return;

    // If this user was removed from the group
    if (data['removed'] == true) {
      Get.until(
        (route) => route.settings.name == ChatAppRoutes.CHAT_LIST,
      );
      return;
    }

    // If full conversation data is present, update in-place
    if (data.containsKey('id') && data.containsKey('type')) {
      try {
        final updated = ConversationModel.fromJson(data);
        conversation.value = updated;
        groupNameController.text = updated.displayNameFor(currentUserId);

        // Rebuild members from the response
        if (data['participants'] != null) {
          final participantList = data['participants'] as List;
          members.value = participantList
              .map((p) =>
                  GroupMemberModel.fromJson(p as Map<String, dynamic>))
              .toList();
          _sortMembers();
        } else {
          _extractMembers(updated);
        }
      } catch (_) {
        loadGroupInfo();
      }
    } else {
      loadGroupInfo();
    }
  }

  // ── Data Loading ──────────────────────────────────────────────────────

  void _loadMembers() {
    _extractMembers(conversation.value);
    loadGroupInfo();
  }

  /// Extracts members from the conversation model.
  /// Tries `groupMembers` first, falls back to building from `participants`.
  void _extractMembers(ConversationModel conv) {
    if (conv.groupMembers != null && conv.groupMembers!.isNotEmpty) {
      members.value = List.from(conv.groupMembers!);
    } else if (conv.participants != null && conv.participants!.isNotEmpty) {
      members.value = conv.participants!
          .map((p) => GroupMemberModel(
                userId: p.id,
                name: p.name,
                avatarUrl: p.avatarUrl,
                role: GroupRole.member,
              ))
          .toList();
    }
    _sortMembers();
  }

  /// Sorts members: owner first, then admins, then regular members.
  void _sortMembers() {
    members.sort((a, b) {
      final aRank = a.role == GroupRole.owner ? 0 : (a.role == GroupRole.admin ? 1 : 2);
      final bRank = b.role == GroupRole.owner ? 0 : (b.role == GroupRole.admin ? 1 : 2);
      if (aRank != bRank) return aRank.compareTo(bRank);
      return a.name.compareTo(b.name);
    });
  }

  Future<void> loadGroupInfo() async {
    try {
      isLoading.value = true;
      final ApiResponseModel response =
          await _chatRepository.getConversationById(conversation.value.id);

      if (response.isSuccessful && response.data != null) {
        final rawData = response.data;
        final convData = rawData is Map && rawData.containsKey('data')
            ? rawData['data'] as Map<String, dynamic>
            : rawData as Map<String, dynamic>;
        final updated = ConversationModel.fromJson(convData);
        conversation.value = updated;

        // Build members from the response — participants include role info
        if (convData['participants'] != null) {
          final participantList = convData['participants'] as List;
          members.value = participantList
              .map((p) =>
                  GroupMemberModel.fromJson(p as Map<String, dynamic>))
              .toList();
        } else {
          _extractMembers(updated);
        }
        _sortMembers();

        groupNameController.text = updated.displayNameFor(currentUserId);
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
        // Don't add optimistically — the server broadcasts
        // 'conversation:updated' with the full member list, and
        // _handleConversationUpdated will update the members list.
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
            // Don't remove optimistically — the server broadcasts
            // 'conversation:updated' which will refresh the member list.
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
