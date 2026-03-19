import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/extension/datetime_extensions.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../widgets/online_indicator.dart';
import '../chat_detail_controller.dart';
import 'message_bubble.dart';
import 'message_input_bar.dart';
import 'message_search_overlay.dart';
import 'typing_indicator_widget.dart';

class ChatDetailViewDesktop extends StatelessWidget {
  const ChatDetailViewDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    // Guard: during controller transitions (switching chats on desktop),
    // the controller may not be registered yet. Show a loading state.
    if (!Get.isRegistered<ChatDetailController>()) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = Get.find<ChatDetailController>();
    if (controller.isDisposed) {
      return const Center(child: CircularProgressIndicator());
    }

    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Obx(() {
          // Show search overlay when active
          if (controller.isSearching.value) {
            return Column(
              children: [
                _buildHeaderBar(context, colors, controller),
                const Expanded(child: MessageSearchOverlay()),
              ],
            );
          }

          return Column(
            children: [
              _buildHeaderBar(context, colors, controller),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          _buildMessageList(context, colors, controller),
                          Positioned(
                            right: 16,
                            bottom: 8,
                            child: Obx(() =>
                                controller.showScrollToBottom.value ||
                                        controller.isViewingOldMessages.value
                                    ? FloatingActionButton.small(
                                        onPressed: controller.scrollToBottom,
                                        backgroundColor: colors.surfaceColor,
                                        elevation: 3,
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          color: colors.primaryColor,
                                        ),
                                      )
                                    : const SizedBox.shrink()),
                          ),
                        ],
                      ),
                    ),
                    Obx(() {
                      if (!Get.isRegistered<ChatDetailController>()) {
                        return const SizedBox.shrink();
                      }
                      if (controller.isRemovedFromGroup.value) {
                        return const SizedBox.shrink();
                      }
                      final users = controller.typingUsers.toList();
                      return TypingIndicatorWidget(typingUsers: users);
                    }),
                    const MessageInputBar(),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Header Bar ──────────────────────────────────────────────────────────

  Widget _buildHeaderBar(
      BuildContext context, ChatColors colors, ChatDetailController controller) {
    final conversation = controller.conversation;
    final otherUser = controller.otherParticipant;

    final displayName = conversation.displayNameFor(controller.currentUserId);
    final avatarUrl = controller.isGroup
        ? conversation.avatarUrl
        : otherUser?.avatarUrl ?? conversation.avatarUrl;
    final avatarName = controller.isGroup ? displayName : otherUser?.name ?? displayName;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.dimenToPx16,
        vertical: AppSizes.dimenToPx12,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: colors.dividerColor,
            width: AppSizes.dimenToPx1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar + Name — tappable for group info
          GestureDetector(
            onTap: (controller.isGroup && !controller.isRemovedFromGroup.value)
                ? () => Get.toNamed(ChatAppRoutes.GROUP_INFO,
                    arguments: controller.conversation)
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    AvatarWidget(
                      imageUrl: avatarUrl,
                      name: avatarName,
                      size: AppSizes.avatarMedium,
                    ),
                    if (!controller.isGroup && otherUser != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Obx(() => OnlineIndicator(
                          isOnline: controller.otherUserPresence.value.isOnline,
                          size: AppSizes.onlineIndicatorSize,
                          borderColor: colors.surfaceColor,
                        )),
                      ),
                  ],
                ),
                const SizedBox(width: AppSizes.dimenToPx12),
              ],
            ),
          ),

          // Name + status — tappable for group info
          Expanded(
            child: GestureDetector(
              onTap: (controller.isGroup && !controller.isRemovedFromGroup.value)
                  ? () => Get.toNamed(ChatAppRoutes.GROUP_INFO,
                      arguments: controller.conversation)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => Text(
                    controller.conversation.displayNameFor(controller.currentUserId),
                    style: ChatTextStyles.conversationTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(height: AppSizes.dimenToPx2),
                  Obx(() {
                  if (controller.typingUsers.isNotEmpty) {
                    final typingText = controller.typingUsers.length == 1
                        ? '${controller.typingUsers.first} ${Keys.Is_typing.tr}'
                        : '${controller.typingUsers.length} ${Keys.People_typing.tr}';
                    return Text(
                      typingText,
                      style: ChatTextStyles.caption.copyWith(
                        color: colors.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }

                  if (!controller.isGroup && otherUser != null) {
                    final isOnline = controller.otherUserPresence.value.isOnline;
                    return Text(
                      isOnline ? Keys.Online.tr : Keys.Offline.tr,
                      style: ChatTextStyles.caption.copyWith(
                        color: isOnline
                            ? colors.onlineIndicatorColor
                            : colors.textLight,
                      ),
                      maxLines: 1,
                    );
                  }

                  if (controller.isGroup) {
                    final memberCount =
                        controller.conversation.participants?.length ?? 0;
                    return Text(
                      '$memberCount ${Keys.Members.tr}',
                      style: ChatTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                    );
                  }

                  return const SizedBox.shrink();
                }),
              ],
            ),
            ),
          ),

          // Action icons
          _HeaderIconButton(
            icon: Icons.search,
            color: colors.iconColor,
            onTap: controller.toggleSearch,
          ),
          _HeaderIconButton(
            icon: Icons.videocam_outlined,
            color: colors.iconColor,
            onTap: () {
              // Video call placeholder
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colors.iconColor),
            color: colors.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'search':
                  controller.toggleSearch();
                  break;
                case 'group_info':
                  Get.toNamed(ChatAppRoutes.GROUP_INFO,
                      arguments: controller.conversation);
                  break;
              }
            },
            itemBuilder: (ctx) {
              final menuColors = ChatColors.getInstance(ctx);
              return [
                if (controller.isGroup && !controller.isRemovedFromGroup.value)
                  PopupMenuItem(
                    value: 'group_info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: menuColors.textPrimary),
                        const SizedBox(width: 12),
                        Text(Keys.Group_Info.tr,
                            style: TextStyle(color: menuColors.textPrimary)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 20, color: menuColors.textPrimary),
                      const SizedBox(width: 12),
                      Text(Keys.Search.tr,
                          style: TextStyle(color: menuColors.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'media',
                  child: Row(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 20, color: menuColors.textPrimary),
                      const SizedBox(width: 12),
                      Text(Keys.Media.tr,
                          style: TextStyle(color: menuColors.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'mute',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 20, color: menuColors.textPrimary),
                      const SizedBox(width: 12),
                      Text(Keys.Mute.tr,
                          style: TextStyle(color: menuColors.textPrimary)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  // ── Message List ────────────────────────────────────────────────────────

  Widget _buildMessageList(
      BuildContext context, ChatColors colors, ChatDetailController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(
            color: colors.primaryColor,
          ),
        );
      }

      if (controller.messages.isEmpty) {
        return Center(
          child: Text(
            Keys.Send_first_message.tr,
            textAlign: TextAlign.center,
            style: ChatTextStyles.body.copyWith(
              color: colors.textLight,
            ),
          ),
        );
      }

      final itemCount = controller.messages.length +
          (controller.isLoadingMore.value ? 1 : 0);

      return ScrollablePositionedList.builder(
        itemScrollController: controller.itemScrollController,
        itemPositionsListener: controller.itemPositionsListener,
        reverse: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.dimenToPx8,
          vertical: AppSizes.dimenToPx8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Loading indicator at the top (end of reversed list)
          if (index == controller.messages.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.dimenToPx16,
              ),
              child: Center(
                child: SizedBox(
                  width: AppSizes.dimenToPx24,
                  height: AppSizes.dimenToPx24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primaryColor,
                  ),
                ),
              ),
            );
          }

          final message = controller.messages[index];
          final isMyMessage = controller.isMyMessage(message);

          // Date separator logic (reversed list: next index is older)
          Widget? dateSeparator;
          if (index == controller.messages.length - 1) {
            dateSeparator = _buildDateSeparator(context, message.createdAt, colors);
          } else {
            final previousMessage = controller.messages[index + 1];
            if (!message.createdAt.toLocal().isSameDay(
                previousMessage.createdAt.toLocal())) {
              dateSeparator =
                  _buildDateSeparator(context, message.createdAt, colors);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dateSeparator != null) dateSeparator,
              Obx(() => MessageBubble(
                message: message,
                isMyMessage: isMyMessage,
                isGroup: controller.isGroup,
                isHighlighted:
                    controller.highlightedMessageId.value == message.id,
                onReply: () => controller.setReplyTo(message),
                onDelete: (forEveryone) =>
                    controller.deleteMessage(message.id, forEveryone: forEveryone),
                onTapReply: (parentId) =>
                    controller.scrollToMessage(parentId),
                onViewReaders: controller.isGroup
                    ? () => controller.showMessageReaders(message.id)
                    : null,
              )),
            ],
          );
        },
      );
    });
  }

  // ── Date Separator ──────────────────────────────────────────────────────

  Widget _buildDateSeparator(
      BuildContext context, DateTime date, ChatColors colors) {
    final local = date.toLocal();
    String label;
    if (local.isToday) {
      label = Keys.Today.tr;
    } else if (local.isYesterday) {
      label = Keys.Yesterday.tr;
    } else if (local.isThisYear) {
      label =
          '${_monthName(local.month)} ${local.day}';
    } else {
      label =
          '${_monthName(local.month)} ${local.day}, ${local.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.dimenToPx8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.dimenToPx12,
            vertical: AppSizes.dimenToPx4,
          ),
          decoration: BoxDecoration(
            color: colors.inputBackgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
          ),
          child: Text(
            label,
            style: ChatTextStyles.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _monthName(int month) {
    final months = [
      Keys.Jan.tr, Keys.Feb.tr, Keys.Mar.tr, Keys.Apr.tr, Keys.May.tr, Keys.Jun.tr,
      Keys.Jul.tr, Keys.Aug.tr, Keys.Sep.tr, Keys.Oct.tr, Keys.Nov.tr, Keys.Dec.tr,
    ];
    return months[month - 1];
  }
}

// ── Header Icon Button ────────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.dimenToPx20),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.dimenToPx8),
        child: Icon(icon, size: AppSizes.dimenToPx22, color: color),
      ),
    );
  }
}
