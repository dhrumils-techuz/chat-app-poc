import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/extension/datetime_extensions.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../widgets/online_indicator.dart';
import '../chat_detail_controller.dart';
import 'message_bubble.dart';
import 'message_input_bar.dart';
import 'typing_indicator_widget.dart';

class ChatDetailViewDesktop extends GetView<ChatDetailController> {
  const ChatDetailViewDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Container(
      color: colors.backgroundColor,
      child: Column(
        children: [
          // ── Header Bar ──────────────────────────────────────────────
          _buildHeaderBar(context, colors),

          // ── Body: Messages + Input ─────────────────────────────────
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildMessageList(context, colors)),

                // Typing indicator
                Obx(() => TypingIndicatorWidget(
                      typingUsers: controller.typingUsers,
                    )),

                // Message input bar
                const MessageInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header Bar ──────────────────────────────────────────────────────────

  Widget _buildHeaderBar(BuildContext context, ChatColors colors) {
    final conversation = controller.conversation;
    final otherUser = controller.otherParticipant;

    final displayName = conversation.displayName;
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
          // Avatar with online indicator
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
                  child: OnlineIndicator(
                    isOnline: otherUser.presence.isOnline,
                    size: AppSizes.onlineIndicatorSize,
                    borderColor: colors.surfaceColor,
                  ),
                ),
            ],
          ),

          const SizedBox(width: AppSizes.dimenToPx12),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: ChatTextStyles.conversationTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.dimenToPx2),
                Obx(() {
                  if (controller.typingUsers.isNotEmpty) {
                    final typingText = controller.typingUsers.length == 1
                        ? '${controller.typingUsers.first} is typing...'
                        : '${controller.typingUsers.length} people typing...';
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
                    return Text(
                      otherUser.presence.isOnline ? 'Online' : 'Offline',
                      style: ChatTextStyles.caption.copyWith(
                        color: otherUser.presence.isOnline
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
                      '$memberCount members',
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

          // Action icons
          _HeaderIconButton(
            icon: Icons.search,
            color: colors.iconColor,
            onTap: () {
              // Search placeholder
            },
          ),
          _HeaderIconButton(
            icon: Icons.videocam_outlined,
            color: colors.iconColor,
            onTap: () {
              // Video call placeholder
            },
          ),
          _HeaderIconButton(
            icon: Icons.more_vert,
            color: colors.iconColor,
            onTap: () {
              // More options placeholder
            },
          ),
        ],
      ),
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
            'No messages yet.\nSend the first message!',
            textAlign: TextAlign.center,
            style: ChatTextStyles.body.copyWith(
              color: colors.textLight,
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
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final message = controller.messages[index];
          final isMyMessage = controller.isMyMessage(message);

          // Date separator logic (reversed list: next index is older)
          Widget? dateSeparator;
          if (index == controller.messages.length - 1) {
            dateSeparator = _buildDateSeparator(context, message.createdAt, colors);
          } else {
            final previousMessage = controller.messages[index + 1];
            if (!message.createdAt.isSameDay(previousMessage.createdAt)) {
              dateSeparator =
                  _buildDateSeparator(context, message.createdAt, colors);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dateSeparator != null) dateSeparator,
              MessageBubble(
                message: message,
                isMyMessage: isMyMessage,
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

  Widget _buildDateSeparator(
      BuildContext context, DateTime date, ChatColors colors) {
    String label;
    if (date.isToday) {
      label = 'Today';
    } else if (date.isYesterday) {
      label = 'Yesterday';
    } else if (date.isThisYear) {
      label =
          '${_monthName(date.month)} ${date.day}';
    } else {
      label =
          '${_monthName(date.month)} ${date.day}, ${date.year}';
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
