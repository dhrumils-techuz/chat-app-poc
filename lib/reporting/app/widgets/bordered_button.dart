import 'package:flutter/material.dart';

import '../../core/theme/color.dart';
import '../../core/theme/text_style.dart';
import '../../core/values/app_sizes.dart';

class BorderedButton extends StatelessWidget {
  const BorderedButton({
    super.key,
    required this.text,
    this.padding,
    required this.onTap,
  });

  final String text;
  final EdgeInsets? padding;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.getInstance(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSizes.dimenToPx30,
              vertical: AppSizes.dimenToPx12,
            ),
        decoration: ShapeDecoration(
          color: colors.surfaceColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: AppSizes.dimenToPx1,
              color: colors.primaryColor,
            ),
            borderRadius: BorderRadius.circular(
              AppSizes.dimenToPx8,
            ),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.primaryTextBoldW700.copyWith(
              color: colors.primaryColor,
              fontSize: AppTextSizes.text16,
            ),
          ),
        ),
      ),
    );
  }
}
