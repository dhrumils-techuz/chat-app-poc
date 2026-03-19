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

class ChatDetailViewMobile extends GetView<ChatDetailController> {
  const ChatDetailViewMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: _buildAppBar(context, colors),
      body: Obx(() {
        // Show search overlay when active
        if (controller.isSearching.value) {
          return const MessageSearchOverlay();
        }

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildMessageList(context, colors),
                  // Scroll-to-bottom FAB
                  Positioned(
                    right: 16,
                    bottom: 8,
                    child: Obx(() => controller.showScrollToBottom.value ||
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
              if (controller.isRemovedFromGroup.value) {
                return const SizedBox.shrink();
              }
              if (controller.typingUsers.isNotEmpty) {
                return TypingIndicatorWidget(
                  typingUsers: controller.typingUsers,
                );
              }
              return const SizedBox.shrink();
            }),
            const MessageInputBar(),
          ],
        );
      }),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, ChatColors colors) {
    return AppBar(
      backgroundColor: colors.surfaceColor,
      foregroundColor: colors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Get.back();
          }
        },
      ),
      titleSpacing: 0,
      title: Obx(() => GestureDetector(
        onTap: (controller.isGroup && !controller.isRemovedFromGroup.value)
            ? () => Get.toNamed(ChatAppRoutes.GROUP_INFO,
                arguments: controller.conversation)
            : null,
        child: Row(
          children: [
            Stack(
              children: [
                AvatarWidget(
                  imageUrl: controller.isGroup
                      ? controller.conversation.avatarUrl
                      : controller.otherParticipant?.avatarUrl ??
                          controller.conversation.avatarUrl,
                  name: controller.conversation.displayNameFor(controller.currentUserId),
                  size: AppSizes.avatarSmall,
                ),
                if (!controller.isGroup && controller.otherParticipant != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Obx(() => OnlineIndicator(
                      isOnline: controller.otherUserPresence.value.isOnline,
                      size: AppSizes.onlineIndicatorSize - 2,
                      borderColor: colors.surfaceColor,
                    )),
                  ),
              ],
            ),
            const SizedBox(width: AppSizes.dimenToPx10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.conversation.displayNameFor(controller.currentUserId),
                    style: ChatTextStyles.heading.copyWith(
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.dimenToPx2),
                  Obx(() {
                    if (controller.typingUsers.isNotEmpty) {
                      return Text(
                        _buildTypingText(),
                        style: ChatTextStyles.caption.copyWith(
                          color: colors.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                    final other = controller.otherParticipant;
                    if (other != null && controller.otherUserPresence.value.isOnline) {
                      return Text(
                        Keys.Online.tr,
                        style: ChatTextStyles.caption.copyWith(
                          color: colors.onlineIndicatorColor,
                        ),
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
                      );
                    }
                    return Text(
                      Keys.Offline.tr,
                      style: ChatTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      )),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam, color: colors.iconColor),
          onPressed: () {
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
          itemBuilder: (context) {
            final menuColors = ChatColors.getInstance(context);
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
    );
  }

  // ── Message List ────────────────────────────────────────────────────────

  Widget _buildMessageList(BuildContext context, ChatColors colors) {
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
            Keys.No_messages_yet.tr,
            style: ChatTextStyles.body.copyWith(
              color: colors.textSecondary,
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
          final bool showDateSeparator = _shouldShowDateSeparator(index);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDateSeparator)
                _buildDateSeparator(context, message.createdAt, colors),
              Obx(() => MessageBubble(
                message: message,
                isMyMessage: controller.isMyMessage(message),
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

  bool _shouldShowDateSeparator(int index) {
    final messages = controller.messages;
    final currentMessage = messages[index];

    // In a reversed list, the next message (index + 1) is older.
    // Show separator if this is the oldest message or the next (older) message
    // is on a different day. Use local time for day comparison.
    if (index == messages.length - 1) return true;

    final olderMessage = messages[index + 1];
    return !currentMessage.createdAt.toLocal().isSameDay(
        olderMessage.createdAt.toLocal());
  }

  Widget _buildDateSeparator(
    BuildContext context,
    DateTime date,
    ChatColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.dimenToPx12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.dimenToPx12,
            vertical: AppSizes.dimenToPx6,
          ),
          decoration: BoxDecoration(
            color: colors.inputBackgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
          ),
          child: Text(
            _formatDateSeparator(date),
            style: ChatTextStyles.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateSeparator(DateTime date) {
    final local = date.toLocal();
    if (local.isToday) return Keys.Today.tr;
    if (local.isYesterday) return Keys.Yesterday.tr;

    if (local.isThisYear) {
      return '${_monthName(local.month)} ${local.day}';
    }
    return '${_monthName(local.month)} ${local.day}, ${local.year}';
  }

  String _monthName(int month) {
    final months = [
      Keys.Jan.tr, Keys.Feb.tr, Keys.Mar.tr, Keys.Apr.tr, Keys.May.tr, Keys.Jun.tr,
      Keys.Jul.tr, Keys.Aug.tr, Keys.Sep.tr, Keys.Oct.tr, Keys.Nov.tr, Keys.Dec.tr,
    ];
    return months[month - 1];
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _buildTypingText() {
    final users = controller.typingUsers;
    if (users.length == 1) return '${users.first} ${Keys.Is_typing.tr}';
    if (users.length == 2) return '${users[0]} and ${users[1]} ${Keys.People_typing.tr}';
    return '${users.length} ${Keys.People_typing.tr}';
  }
}
