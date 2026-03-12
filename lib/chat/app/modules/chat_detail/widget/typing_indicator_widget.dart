import 'package:flutter/material.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';

class TypingIndicatorWidget extends StatefulWidget {
  const TypingIndicatorWidget({
    super.key,
    required this.typingUsers,
  });

  final List<String> typingUsers;

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _typingText {
    if (widget.typingUsers.isEmpty) return '';
    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers.first} is typing';
    }
    if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers[0]} and ${widget.typingUsers[1]} are typing';
    }
    return '${widget.typingUsers.length} people are typing';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    final colors = ChatColors.getInstance(context);

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _typingText,
            style: ChatTextStyles.caption.copyWith(
              color: colors.primaryColor,
            ),
          ),
          const SizedBox(width: 2),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final progress =
                      ((_animationController.value - delay) % 1.0).clamp(0.0, 1.0);
                  final offset = -3.0 * (1.0 - (2.0 * progress - 1.0).abs());

                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: Text(
                      '.',
                      style: ChatTextStyles.caption.copyWith(
                        color: colors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
