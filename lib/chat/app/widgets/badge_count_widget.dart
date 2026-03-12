import 'package:flutter/material.dart';

import '../../core/theme/color.dart';
import '../../core/theme/text_style.dart';
import '../../core/values/app_sizes.dart';

class BadgeCountWidget extends StatelessWidget {
  const BadgeCountWidget({
    super.key,
    required this.count,
    this.size = AppSizes.badgeSize,
    this.backgroundColor,
    this.textColor,
    this.maxCount = 99,
  });

  final int count;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final colors = ChatColors.getInstance(context);
    final displayText = count > maxCount ? '$maxCount+' : '$count';
    final isWide = displayText.length > 2;

    return Container(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSizes.dimenToPx6 : 0,
      ),
      decoration: BoxDecoration(
        gradient: backgroundColor == null ? AppColor.primaryGradient : null,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: ChatTextStyles.badgeCount.copyWith(
          color: textColor ?? colors.onPrimaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
