import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/extension/datetime_extensions.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../data/model/conversation_model.dart';
import '../../../data/types/message_status_type.dart';
import '../../../data/types/message_type.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../widgets/badge_count_widget.dart';
import '../../../widgets/online_indicator.dart';
import '../chat_list_controller.dart';

class ChatListItem extends StatelessWidget {
  const ChatListItem({
    super.key,
    required this.conversation,
  });

  final ConversationModel conversation;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);
    final controller = Get.find<ChatListController>();

    return InkWell(
      onTap: () => controller.openChat(conversation),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.dimenToPx16,
              vertical: AppSizes.dimenToPx12,
            ),
            child: Row(
              children: [
                // Avatar with online indicator
                _buildAvatar(controller, colors),
                const SizedBox(width: AppSizes.dimenToPx12),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleRow(colors),
                      const SizedBox(height: AppSizes.dimenToPx4),
                      Obx(() => _buildSubtitle(controller, colors)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.dimenToPx8),

                // Timestamp and badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTimestamp(colors),
                    const SizedBox(height: AppSizes.dimenToPx6),
                    _buildTrailingIndicators(colors),
                  ],
                ),
              ],
            ),
          ),

          // Divider inset by avatar + spacing (56 + 12 + 16 = 84 ~80)
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.dimenToPx80),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: colors.dividerColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ChatListController controller, ChatColors colors) {
    final isOnline = controller.isConversationOnline(conversation);

    return SizedBox(
      width: AppSizes.avatarLarge,
      height: AppSizes.avatarLarge,
      child: Stack(
        children: [
          AvatarWidget(
            imageUrl: conversation.avatarUrl,
            name: conversation.displayName,
            size: AppSizes.avatarLarge,
          ),
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: OnlineIndicator(
                isOnline: true,
                borderColor: colors.surfaceColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(ChatColors colors) {
    return Text(
      conversation.displayName,
      style: ChatTextStyles.conversationTitle.copyWith(
        color: colors.textPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(ChatListController controller, ChatColors colors) {
    // Show typing indicator if someone is typing in this conversation
    final typingUser = controller.typingIndicators[conversation.id];
    if (typingUser != null) {
      return Text(
        conversation.isGroup
            ? '$typingUser ${Keys.Is_typing.tr}'
            : Keys.Typing.tr,
        style: ChatTextStyles.conversationPreview.copyWith(
          color: colors.primaryColor,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lastMessage = conversation.lastMessage;

    if (lastMessage == null) {
      return Text(
        Keys.No_messages_yet.tr,
        style: ChatTextStyles.conversationPreview.copyWith(
          color: colors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (lastMessage.isDeleted) {
      return Row(
        children: [
          Icon(
            Icons.block,
            size: AppSizes.dimenToPx14,
            color: colors.textSecondary,
          ),
          const SizedBox(width: AppSizes.dimenToPx4),
          Expanded(
            child: Text(
              Keys.Message_deleted.tr,
              style: ChatTextStyles.conversationPreview.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Build preview text
    final List<InlineSpan> spans = [];

    // Show read receipt icon for messages sent by current user
    if (lastMessage.senderId == controller.currentUserId) {
      IconData statusIcon;
      Color statusColor;
      switch (lastMessage.status) {
        case MessageStatusType.sending:
          statusIcon = Icons.access_time;
          statusColor = colors.textTimestamp;
        case MessageStatusType.sent:
          statusIcon = Icons.check;
          statusColor = colors.textTimestamp;
        case MessageStatusType.delivered:
          statusIcon = Icons.done_all;
          statusColor = colors.textTimestamp;
        case MessageStatusType.read:
          statusIcon = Icons.done_all;
          statusColor = colors.primaryColor;
        case MessageStatusType.failed:
          statusIcon = Icons.error_outline;
          statusColor = colors.errorColor;
      }
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(statusIcon, size: 14, color: statusColor),
        ),
      ));
    }

    // Show sender name in group chats
    if (conversation.isGroup && lastMessage.senderName != null) {
      final isMe = lastMessage.senderId == controller.currentUserId;
      spans.add(TextSpan(
        text: isMe ? '${Keys.You.tr}: ' : '${lastMessage.senderName}: ',
        style: ChatTextStyles.conversationPreview.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ));
    }

    // Message content based on type
    if (lastMessage.isTextMessage) {
      spans.add(TextSpan(
        text: lastMessage.content ?? '',
        style: ChatTextStyles.conversationPreview.copyWith(
          color: colors.textSecondary,
        ),
      ));
    } else {
      final typeLabel = _getMessageTypeLabel(lastMessage.type);
      final typeIcon = _getMessageTypeIcon(lastMessage.type);

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Icon(
          typeIcon,
          size: AppSizes.dimenToPx14,
          color: colors.textSecondary,
        ),
      ));
      spans.add(TextSpan(
        text: ' $typeLabel',
        style: ChatTextStyles.conversationPreview.copyWith(
          color: colors.textSecondary,
        ),
      ));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  Widget _buildTimestamp(ChatColors colors) {
    final time = conversation.lastMessageAt;
    if (time == null) return const SizedBox.shrink();

    return Text(
      _formatTimestamp(time),
      style: ChatTextStyles.messageTimestamp.copyWith(
        color: conversation.hasUnread
            ? colors.primaryColor
            : colors.textTimestamp,
      ),
    );
  }

  Widget _buildTrailingIndicators(ChatColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (conversation.isMuted)
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.dimenToPx4),
            child: Icon(
              Icons.volume_off,
              size: AppSizes.dimenToPx14,
              color: colors.textTimestamp,
            ),
          ),
        if (conversation.hasUnread)
          BadgeCountWidget(count: conversation.unreadCount),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _formatTimestamp(DateTime time) {
    final local = time.toLocal();
    if (local.isToday) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    if (local.isYesterday) {
      return Keys.Yesterday.tr;
    }

    if (local.isThisWeek) {
      final days = [Keys.Mon.tr, Keys.Tue.tr, Keys.Wed.tr, Keys.Thu.tr, Keys.Fri.tr, Keys.Sat.tr, Keys.Sun.tr];
      return days[local.weekday - 1];
    }

    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = (local.year % 100).toString().padLeft(2, '0');
    return '$month/$day/$year';
  }

  String _getMessageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.image:
        return Keys.Photo.tr;
      case MessageType.audio:
        return Keys.Audio.tr;
      case MessageType.document:
        return Keys.Document.tr;
      case MessageType.file:
        return Keys.File.tr;
      case MessageType.system:
        return Keys.System_message.tr;
      case MessageType.text:
        return '';
    }
  }

  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.image:
        return Icons.photo_camera;
      case MessageType.audio:
        return Icons.mic;
      case MessageType.document:
        return Icons.description;
      case MessageType.file:
        return Icons.attach_file;
      case MessageType.system:
        return Icons.info_outline;
      case MessageType.text:
        return Icons.chat_bubble_outline;
    }
  }
}
