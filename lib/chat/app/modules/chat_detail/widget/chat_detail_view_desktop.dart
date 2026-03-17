import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
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
                Obx(() {
                  final users = controller.typingUsers.toList();
                  return TypingIndicatorWidget(
                    typingUsers: users,
                  );
                }),

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
                  child: Obx(() => OnlineIndicator(
                    isOnline: controller.otherUserPresence.value.isOnline,
                    size: AppSizes.onlineIndicatorSize,
                    borderColor: colors.surfaceColor,
                  )),
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
            Keys.Send_first_message.tr,
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
          // Use local time for day comparison
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
              Obx(() => Container(
                key: controller.getKeyForMessage(message.id),
                child: MessageBubble(
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
                ),
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
