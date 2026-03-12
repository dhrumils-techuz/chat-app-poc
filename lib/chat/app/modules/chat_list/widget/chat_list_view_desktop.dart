import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/adaptive_layout.dart';
import '../../../widgets/empty_state_widget.dart';
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
          'WhatsUp',
          style: ChatTextStyles.appBarTitle.copyWith(
            color: colors.primaryColor,
          ),
        ),
        actions: [
          Container(
            width: AppSizes.dimenToPx40,
            height: AppSizes.dimenToPx40,
            margin: const EdgeInsets.only(right: AppSizes.dimenToPx4),
            decoration: BoxDecoration(
              color: AppColor.primary10,
              borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.search,
                color: colors.primaryColor,
                size: AppSizes.dimenToPx20,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: colors.iconColor,
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
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_chat',
                child: Text('New Chat'),
              ),
              const PopupMenuItem(
                value: 'new_group',
                child: Text('New Group'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
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

      if (items.isEmpty) {
        return EmptyStateWidget(
          icon: Icons.chat_bubble_outline_rounded,
          title: controller.searchQuery.value.isNotEmpty
              ? 'No results found'
              : 'No conversations yet',
          subtitle: controller.searchQuery.value.isNotEmpty
              ? 'Try a different search term'
              : 'Start a new chat to begin messaging',
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshConversations,
        color: colors.primaryColor,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Obx(() {
              final isSelected = controller.selectedConversationId.value ==
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
    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: Center(
        child: EmptyStateWidget(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Chat Detail',
          subtitle:
              'Chat detail view will appear here.\nConversation ID: ${controller.selectedConversationId.value ?? ""}',
        ),
      ),
    );
  }
}
