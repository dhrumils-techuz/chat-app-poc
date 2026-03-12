import 'package:flutter/material.dart';

import '../../core/theme/color.dart';

class CustomDivider extends StatelessWidget {
  const CustomDivider({
    super.key,
    required this.height,
    this.margin,
    this.dividerColor,
    this.isVertical = true,
  });

  final double height;
  final EdgeInsetsGeometry? margin;
  final Color? dividerColor;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.getInstance(context);
    return isVertical
        ? Container(
            color: dividerColor ?? colors.dividerColor,
            height: height,
            margin: margin,
          )
        : Container(
            color: dividerColor ?? colors.dividerColor,
            width: height,
            margin: margin,
          );
  }
}
