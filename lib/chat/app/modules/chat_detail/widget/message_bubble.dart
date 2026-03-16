import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../data/model/message_model.dart';
import 'media_preview_widget.dart';
import 'message_status_indicator.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.isGroup,
    this.onReply,
    this.onDelete,
  });

  final MessageModel message;
  final bool isMyMessage;
  final bool isGroup;
  final VoidCallback? onReply;
  final void Function(bool forEveryone)? onDelete;

  @override
  Widget build(BuildContext context) {
    // System messages rendered differently
    if (message.isSystemMessage) {
      return _buildSystemMessage(context);
    }

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.bubbleMaxWidth,
          ),
          margin: EdgeInsets.only(
            left: isMyMessage ? 60 : 8,
            right: isMyMessage ? 8 : 60,
            top: 2,
            bottom: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isMyMessage
                ? AppColor.sentBubble
                : AppColor.receivedBubble,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMyMessage ? AppSizes.bubbleRadius : 4),
              topRight: Radius.circular(isMyMessage ? 4 : AppSizes.bubbleRadius),
              bottomLeft: const Radius.circular(AppSizes.bubbleRadius),
              bottomRight: const Radius.circular(AppSizes.bubbleRadius),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sender name (group + received only)
              if (isGroup && !isMyMessage) _buildSenderName(context),

              // Reply preview
              if (message.hasReply) _buildReplyPreview(context),

              // Content
              _buildContent(context),

              // Timestamp + status row
              _buildTimestampRow(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── System Message ─────────────────────────────────────────────────────

  Widget _buildSystemMessage(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.inputBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message.content ?? '',
          style: ChatTextStyles.caption.copyWith(
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ── Sender Name ────────────────────────────────────────────────────────

  Widget _buildSenderName(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        message.senderName ?? Keys.Unknown.tr,
        style: ChatTextStyles.captionSemiBold.copyWith(
          color: AppColor.primary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Reply Preview ──────────────────────────────────────────────────────

  Widget _buildReplyPreview(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isMyMessage
            ? colors.primaryColor.withOpacity(0.08)
            : colors.surfaceColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: colors.primaryColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.replyToSenderName ?? Keys.Unknown.tr,
                  style: ChatTextStyles.captionSemiBold.copyWith(
                    color: colors.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  message.replyToContent ?? '',
                  style: ChatTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    // Deleted message
    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          Keys.Message_deleted.tr,
          style: ChatTextStyles.messageBody.copyWith(
            color: colors.textTimestamp,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Media content
        if (message.hasAttachment)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: MediaPreviewWidget(
              attachment: message.attachment!,
              isMyMessage: isMyMessage,
            ),
          ),

        // Text content
        if (message.content != null &&
            message.content!.isNotEmpty &&
            message.isTextMessage)
          Text(
            message.content!,
            style: ChatTextStyles.messageBody.copyWith(
              color: colors.textPrimary,
            ),
          ),

        // Caption for media with text
        if (message.content != null &&
            message.content!.isNotEmpty &&
            !message.isTextMessage &&
            message.hasAttachment)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              message.content!,
              style: ChatTextStyles.messageBody.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  // ── Timestamp Row ──────────────────────────────────────────────────────

  Widget _buildTimestampRow(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    final timeString = _formatTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            timeString,
            style: ChatTextStyles.messageTimestamp.copyWith(
              color: colors.textTimestamp,
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 3),
            MessageStatusIndicator(
              status: message.status,
              size: 14,
            ),
          ],
        ],
      ),
    );
  }

  // ── Context Menu ───────────────────────────────────────────────────────

  void _showContextMenu(BuildContext context) {
    if (message.isDeleted) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        if (onReply != null)
          PopupMenuItem(value: 'reply', child: Text(Keys.Reply.tr)),
        if (message.isTextMessage && message.content != null)
          PopupMenuItem(value: 'copy', child: Text(Keys.Copy.tr)),
        if (isMyMessage && onDelete != null) ...[
          PopupMenuItem(value: 'delete_me', child: Text(Keys.Delete_for_me.tr)),
          PopupMenuItem(
            value: 'delete_all',
            child: Text(Keys.Delete_for_everyone.tr),
          ),
        ] else if (onDelete != null)
          PopupMenuItem(value: 'delete_me', child: Text(Keys.Delete_for_me.tr)),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'reply':
          onReply?.call();
          break;
        case 'copy':
          if (message.content != null) {
            Clipboard.setData(ClipboardData(text: message.content!));
          }
          break;
        case 'delete_me':
          onDelete?.call(false);
          break;
        case 'delete_all':
          onDelete?.call(true);
          break;
      }
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }
}
