import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../data/model/message_model.dart';
import '../../../data/types/message_type.dart';

class ReplyPreviewWidget extends StatelessWidget {
  const ReplyPreviewWidget({
    super.key,
    required this.message,
    required this.onClose,
  });

  final MessageModel message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        border: Border(
          top: BorderSide(color: colors.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Vertical green bar
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 8),

          // Reply content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.senderName ?? Keys.Unknown.tr,
                  style: ChatTextStyles.captionSemiBold.copyWith(
                    color: colors.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getPreviewText(),
                  style: ChatTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              size: 18,
              color: colors.iconColor,
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  String _getPreviewText() {
    if (message.isDeleted) return Keys.Message_deleted.tr;
    if (message.content != null && message.content!.isNotEmpty) {
      return message.content!;
    }
    switch (message.type) {
      case MessageType.image:
        return Keys.Photo.tr;
      case MessageType.audio:
        return Keys.Audio.tr;
      case MessageType.document:
        return Keys.Document.tr;
      case MessageType.file:
        return Keys.File.tr;
      default:
        return '';
    }
  }
}
