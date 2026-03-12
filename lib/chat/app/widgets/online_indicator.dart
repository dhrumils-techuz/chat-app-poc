import 'package:flutter/material.dart';

import '../../core/theme/color.dart';
import '../../core/values/app_sizes.dart';

class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({
    super.key,
    this.isOnline = false,
    this.size = AppSizes.onlineIndicatorSize,
    this.borderWidth = 2.0,
    this.borderColor,
  });

  final bool isOnline;
  final double size;
  final double borderWidth;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    if (!isOnline) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.onlineIndicatorColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? colors.surfaceColor,
          width: borderWidth,
        ),
      ),
    );
  }
}
