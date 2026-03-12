import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../chat_detail_controller.dart';
import 'attachment_picker_widget.dart';
import 'reply_preview_widget.dart';

class MessageInputBar extends GetView<ChatDetailController> {
  const MessageInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            Obx(() {
              final replyMsg = controller.replyingTo.value;
              if (replyMsg == null) return const SizedBox.shrink();
              return ReplyPreviewWidget(
                message: replyMsg,
                onClose: controller.cancelReply,
              );
            }),

            // Input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Emoji button
                  _IconButton(
                    icon: Icons.emoji_emotions_outlined,
                    color: colors.iconColor,
                    onTap: () {
                      // Emoji picker placeholder
                    },
                  ),

                  const SizedBox(width: 4),

                  // Text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: AppSizes.inputBarHeight - 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.inputBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: controller.textController,
                        onChanged: controller.onTextChanged,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: ChatTextStyles.inputText.copyWith(
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: ChatTextStyles.inputText.copyWith(
                            color: colors.textLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Attachment button
                  _IconButton(
                    icon: Icons.attach_file,
                    color: colors.iconColor,
                    onTap: () {
                      AttachmentPickerWidget.show(
                        context,
                        onAttachmentSelected: (type) {
                          // Handle attachment selection
                        },
                      );
                    },
                  ),

                  // Camera button
                  Obx(() {
                    if (controller.messageText.value.isNotEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _IconButton(
                      icon: Icons.camera_alt_outlined,
                      color: colors.iconColor,
                      onTap: () {
                        // Camera placeholder
                      },
                    );
                  }),

                  const SizedBox(width: 4),

                  // Send / Mic button
                  Obx(() {
                    final hasText = controller.messageText.value.isNotEmpty;
                    return GestureDetector(
                      onTap: hasText ? controller.sendTextMessage : null,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          gradient: AppColor.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasText ? Icons.send : Icons.mic,
                          color: AppColor.white,
                          size: 20,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 24, color: color),
      ),
    );
  }
}
