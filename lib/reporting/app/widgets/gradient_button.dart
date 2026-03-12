import 'package:flutter/material.dart';

import '../../core/theme/color.dart';
import '../../core/theme/text_style.dart';
import '../../core/values/app_sizes.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    this.padding,
    this.isEnable = true,
  });

  final String text;
  final EdgeInsets? padding;
  final Function() onTap;
  final bool isEnable;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.getInstance(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isEnable) {
          onTap();
        }
      },
      child: Container(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSizes.dimenToPx30,
              vertical: AppSizes.dimenToPx12,
            ),
        decoration: isEnable
            ? ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.primaryContainer, colors.primaryColor],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.dimenToPx8),
                ),
              )
            : ShapeDecoration(
                color: colors.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.dimenToPx8),
                ),
              ),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.primaryTextBoldW700.copyWith(
              color: isEnable
                  ? colors.colorOnPrimary
                  : colors.colorOnBackgroundSecondary,
              fontSize: AppTextSizes.text16,
            ),
          ),
        ),
      ),
    );
  }
}
