import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/extension/datetime_extensions.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../data/model/conversation_model.dart';
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
                      _buildSubtitle(controller, colors),
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
    final lastMessage = conversation.lastMessage;

    if (lastMessage == null) {
      return Text(
        'No messages yet',
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
              'This message was deleted',
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

    // Show sender name in group chats
    if (conversation.isGroup && lastMessage.senderName != null) {
      final isMe = lastMessage.senderId == controller.currentUserId;
      spans.add(TextSpan(
        text: isMe ? 'You: ' : '${lastMessage.senderName}: ',
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
    if (time.isToday) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    if (time.isYesterday) {
      return 'Yesterday';
    }

    if (time.isThisWeek) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    }

    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final year = (time.year % 100).toString().padLeft(2, '0');
    return '$month/$day/$year';
  }

  String _getMessageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'Photo';
      case MessageType.audio:
        return 'Audio';
      case MessageType.document:
        return 'Document';
      case MessageType.file:
        return 'File';
      case MessageType.system:
        return 'System message';
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
