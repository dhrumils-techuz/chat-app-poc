import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/empty_state_widget.dart';
import '../chat_list_controller.dart';
import 'chat_folder_tabs.dart';
import 'chat_list_item.dart';
import 'search_bar_widget.dart';

class ChatListViewMobile extends GetView<ChatListController> {
  const ChatListViewMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.surfaceColor,
      appBar: _buildAppBar(colors),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.dimenToPx16,
              vertical: AppSizes.dimenToPx8,
            ),
            child: const ChatSearchBarWidget(),
          ),

          // Folder tabs
          Obx(() {
            if (controller.folders.isEmpty) {
              return const SizedBox.shrink();
            }
            return const ChatFolderTabs();
          }),

          // Conversation list
          Expanded(
            child: _buildConversationList(colors),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatColors colors) {
    return AppBar(
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
            onPressed: () {
              // Focus the search bar
            },
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
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'new_group',
              child: Text(Keys.New_Group.tr),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Text(Keys.Settings.tr),
            ),
            PopupMenuItem(
              value: 'profile',
              child: Text(Keys.Profile.tr),
            ),
          ],
        ),
      ],
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
              ? Keys.No_results_found.tr
              : Keys.No_conversations.tr,
          subtitle: controller.searchQuery.value.isNotEmpty
              ? Keys.Try_different_search.tr
              : Keys.Start_new_chat.tr,
          actionText: controller.searchQuery.value.isEmpty
              ? Keys.Start_chat.tr
              : null,
          onAction: controller.searchQuery.value.isEmpty
              ? () => Get.toNamed(ChatAppRoutes.CONTACTS)
              : null,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshConversations,
        color: colors.primaryColor,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ChatListItem(conversation: items[index]);
          },
        ),
      );
    });
  }

  Widget _buildFab() {
    return Container(
      width: AppSizes.dimenToPx60,
      height: AppSizes.dimenToPx60,
      decoration: const BoxDecoration(
        gradient: AppColor.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x3010C17D),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => Get.toNamed(ChatAppRoutes.CONTACTS),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: const Icon(
          Icons.chat,
          color: AppColor.white,
          size: AppSizes.dimenToPx24,
        ),
      ),
    );
  }
}
