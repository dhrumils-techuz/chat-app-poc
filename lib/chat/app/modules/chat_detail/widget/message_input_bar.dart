import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/utils/screen_util.dart';
import '../../../../core/values/app_sizes.dart';
import '../chat_detail_controller.dart';
import 'attachment_picker_widget.dart';
import 'reply_preview_widget.dart';

class MessageInputBar extends GetView<ChatDetailController> {
  const MessageInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);
    final isMobile = ScreenUtil.isMobileWidth(ScreenUtil.width(context));

    return Material(
      color: colors.surfaceColor,
      elevation: 0,
      child: Container(
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
                      child: _MessageTextField(
                        controller: controller,
                        colors: colors,
                        isMobile: isMobile,
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
    ),
    );
  }
}

/// Text field that handles Enter-to-send on non-mobile platforms and
/// keeps focus after sending.
class _MessageTextField extends StatefulWidget {
  const _MessageTextField({
    required this.controller,
    required this.colors,
    required this.isMobile,
  });

  final ChatDetailController controller;
  final ChatColors colors;
  final bool isMobile;

  @override
  State<_MessageTextField> createState() => _MessageTextFieldState();
}

class _MessageTextFieldState extends State<_MessageTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    // Unfocus BEFORE disposing to prevent the focus-change callback from
    // trying to update the selection on an already-disposed TextEditingController.
    // This happens in tablet/desktop mode when switching conversations:
    // ChatDetailController.onClose() disposes textController, but the FocusNode
    // is still alive and fires a focus-lost notification that touches the controller.
    _focusNode.unfocus();
    _focusNode.dispose();
    super.dispose();
  }

  /// On non-mobile: Enter sends message, Shift+Enter inserts newline.
  /// On mobile: Enter always inserts newline (soft keyboard has its own send).
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.isMobile) return KeyEventResult.ignored;

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      final text = widget.controller.textController.text.trim();
      if (text.isNotEmpty) {
        widget.controller.sendTextMessage();
        // Re-request focus after send
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_focusNode.canRequestFocus) {
            _focusNode.requestFocus();
          }
        });
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: TextField(
        controller: widget.controller.textController,
        focusNode: _focusNode,
        onChanged: widget.controller.onTextChanged,
        // On non-mobile, autofocus so user can type immediately
        autofocus: !widget.isMobile,
        maxLines: 5,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        // On mobile, Enter inserts newline via textInputAction
        textInputAction:
            widget.isMobile ? TextInputAction.newline : TextInputAction.none,
        style: ChatTextStyles.inputText.copyWith(
          color: widget.colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: Keys.Type_a_message.tr,
          hintStyle: ChatTextStyles.inputText.copyWith(
            color: widget.colors.textLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          isDense: true,
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
