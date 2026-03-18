import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../data/auth/jwt_auth_service.dart';
import '../../../data/model/conversation_model.dart';
import '../../../data/repository/message_repository.dart';
import '../../../data/service/socket/socket_service.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/adaptive_layout.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../chat_detail/chat_detail_controller.dart';
import '../../chat_detail/widget/chat_detail_view_desktop.dart';
import '../chat_list_controller.dart';
import 'chat_folder_tabs.dart';
import 'chat_list_item.dart';
import 'search_bar_widget.dart';

class ChatListViewDesktop extends GetView<ChatListController> {
  const ChatListViewDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final hasSelection = controller.selectedConversationId.value != null;

        return AdaptiveLayout(
          listPanelWidth: 350,
          listPanel: _buildListPanel(context),
          showDetailPanel: hasSelection,
          detailPanel: hasSelection ? _buildDetailPanel(context) : null,
        );
      }),
    );
  }

  Widget _buildListPanel(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.surfaceColor,
      appBar: AppBar(
        backgroundColor: colors.surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          Keys.AppName.tr,
          style: ChatTextStyles.appBarTitle.copyWith(
            color: colors.primaryColor,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: colors.iconColor,
            ),
            color: colors.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'new_chat':
                  Get.toNamed(ChatAppRoutes.CONTACTS);
                  break;
                case 'new_group':
                  Get.toNamed(ChatAppRoutes.NEW_GROUP);
                  break;
                case 'settings':
                  Get.toNamed(ChatAppRoutes.SETTINGS);
                  break;
                case 'profile':
                  Get.toNamed(ChatAppRoutes.PROFILE);
                  break;
              }
            },
            itemBuilder: (context) {
              final menuColors = ChatColors.getInstance(context);
              return [
                PopupMenuItem(
                  value: 'new_chat',
                  child: Row(
                    children: [
                      Icon(Icons.chat_outlined, size: 20, color: menuColors.textPrimary),
                      const SizedBox(width: 12),
                      Text(Keys.New_Chat.tr,
                          style: TextStyle(color: menuColors.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'new_group',
                  child: Row(
                    children: [
                      Icon(Icons.group_add_outlined, size: 20, color: menuColors.textPrimary),
                      const SizedBox(width: 12),
                      Text(Keys.New_Group.tr,
                          style: TextStyle(color: menuColors.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20, color: menuColors.textPrimary),
                      const SizedBox(width: 12),
                      Text(Keys.Settings.tr,
                          style: TextStyle(color: menuColors.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: menuColors.textPrimary),
                      const SizedBox(width: 12),
                      Text(Keys.Profile.tr,
                          style: TextStyle(color: menuColors.textPrimary)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.dimenToPx16,
              vertical: AppSizes.dimenToPx8,
            ),
            child: const ChatSearchBarWidget(),
          ),
          Obx(() {
            if (controller.folders.isEmpty) {
              return const SizedBox.shrink();
            }
            return const ChatFolderTabs();
          }),
          Expanded(
            child: _buildConversationList(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(ChatColors colors) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(
            color: colors.primaryColor,
          ),
        );
      }

      final items = controller.filteredConversations;

      return RefreshIndicator(
        onRefresh: controller.refreshConversations,
        color: colors.primaryColor,
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 300,
                    child: EmptyStateWidget(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: controller.searchQuery.value.isNotEmpty
                          ? Keys.No_results_found.tr
                          : Keys.No_conversations.tr,
                      subtitle: controller.searchQuery.value.isNotEmpty
                          ? Keys.Try_different_search.tr
                          : Keys.Start_new_chat.tr,
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Obx(() {
                    final isSelected =
                        controller.selectedConversationId.value ==
                            items[index].id;
                    return Container(
                      color: isSelected
                          ? colors.primaryColor.withValues(alpha: 0.08)
                          : null,
                      child: ChatListItem(conversation: items[index]),
                    );
                  });
                },
              ),
      );
    });
  }

  Widget _buildDetailPanel(BuildContext context) {
    final conversationId = controller.selectedConversationId.value;
    if (conversationId == null) return const SizedBox.shrink();

    // Find the conversation from the loaded list
    final conversation = controller.conversations.firstWhereOrNull(
      (c) => c.id == conversationId,
    );
    if (conversation == null) return const SizedBox.shrink();

    // Use a keyed widget so Flutter recreates when the conversation changes
    return _EmbeddedChatDetail(
      key: ValueKey(conversationId),
      conversation: conversation,
    );
  }
}

/// A stateful widget that manages a [ChatDetailController] lifecycle
/// for the desktop split-view embedded detail panel.
class _EmbeddedChatDetail extends StatefulWidget {
  const _EmbeddedChatDetail({
    super.key,
    required this.conversation,
  });

  final ConversationModel conversation;

  @override
  State<_EmbeddedChatDetail> createState() => _EmbeddedChatDetailState();
}

class _EmbeddedChatDetailState extends State<_EmbeddedChatDetail> {
  /// The controller instance this widget owns.
  /// Used to avoid deleting a newer controller created by a sibling widget.
  ChatDetailController? _ownController;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() {
    // Remove any previously registered controller (from a prior selection).
    // Use force: true to skip the onClose lifecycle of the previous controller
    // since we already handle cleanup in dispose(). This prevents race
    // conditions when the old controller's onClose runs during the new
    // widget's initState.
    if (Get.isRegistered<ChatDetailController>()) {
      try {
        Get.delete<ChatDetailController>(force: true);
      } catch (_) {}
    }

    _ownController = ChatDetailController(
      messageRepository: Get.find<MessageRepository>(),
      socketService: Get.find<SocketService>(),
      authService: Get.find<JwtAuthService>(),
      conversation: widget.conversation,
    );
    Get.put(_ownController!);
  }

  @override
  void dispose() {
    // Only delete if the registered controller is still the one WE created.
    // When switching conversations via ValueKey, Flutter creates the new
    // widget's initState() BEFORE disposing the old one. The new initState()
    // already registered a fresh controller — we must NOT delete it here.
    if (Get.isRegistered<ChatDetailController>()) {
      try {
        final current = Get.find<ChatDetailController>();
        if (identical(current, _ownController)) {
          Get.delete<ChatDetailController>();
        }
      } catch (_) {
        // Controller already gone — nothing to clean up
      }
    }
    _ownController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const ChatDetailViewDesktop();
  }
}
