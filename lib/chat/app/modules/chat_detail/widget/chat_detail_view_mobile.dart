import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/extension/datetime_extensions.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../widgets/avatar_widget.dart';
import '../chat_detail_controller.dart';
import 'message_bubble.dart';
import 'message_input_bar.dart';
import 'typing_indicator_widget.dart';

class ChatDetailViewMobile extends GetView<ChatDetailController> {
  const ChatDetailViewMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: _buildAppBar(context, colors),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(context, colors)),
          Obx(() {
            if (controller.typingUsers.isNotEmpty) {
              return TypingIndicatorWidget(
                typingUsers: controller.typingUsers,
              );
            }
            return const SizedBox.shrink();
          }),
          const MessageInputBar(),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, ChatColors colors) {
    return AppBar(
      backgroundColor: colors.surfaceColor,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
        onPressed: () => Get.back(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          AvatarWidget(
            imageUrl: controller.conversation.avatarUrl,
            name: controller.conversation.displayName,
            size: AppSizes.avatarSmall,
          ),
          const SizedBox(width: AppSizes.dimenToPx10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.conversation.displayName,
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
                  if (other != null && other.presence.isOnline) {
                    return Text(
                      'Online',
                      style: ChatTextStyles.caption.copyWith(
                        color: colors.onlineIndicatorColor,
                      ),
                    );
                  }
                  return Text(
                    controller.isGroup ? 'Tap for group info' : 'Offline',
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
      actions: [
        IconButton(
          icon: Icon(Icons.videocam, color: colors.iconColor),
          onPressed: () {
            // Video call placeholder
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: colors.iconColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
          ),
          onSelected: (value) {
            // Handle menu actions
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'search', child: Text('Search')),
            const PopupMenuItem(value: 'media', child: Text('Media')),
            const PopupMenuItem(value: 'mute', child: Text('Mute')),
          ],
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
            'No messages yet',
            style: ChatTextStyles.body.copyWith(
              color: colors.textSecondary,
            ),
          ),
        );
      }

      return ListView.builder(
        controller: controller.scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.dimenToPx8,
          vertical: AppSizes.dimenToPx8,
        ),
        itemCount: controller.messages.length +
            (controller.isLoadingMore.value ? 1 : 0),
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
              MessageBubble(
                message: message,
                isMyMessage: controller.isMyMessage(message),
                isGroup: controller.isGroup,
                onReply: () => controller.setReplyTo(message),
                onDelete: (forEveryone) =>
                    controller.deleteMessage(message.id, forEveryone: forEveryone),
              ),
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
    // is on a different day.
    if (index == messages.length - 1) return true;

    final olderMessage = messages[index + 1];
    return !currentMessage.createdAt.isSameDay(olderMessage.createdAt);
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
    if (date.isToday) return 'Today';
    if (date.isYesterday) return 'Yesterday';

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    if (date.isThisYear) {
      return '${months[date.month - 1]} ${date.day}';
    }
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _buildTypingText() {
    final users = controller.typingUsers;
    if (users.length == 1) return '${users.first} is typing...';
    if (users.length == 2) return '${users[0]} and ${users[1]} are typing...';
    return '${users.length} people are typing...';
  }
}
