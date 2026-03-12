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
    this.isLoading = false,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String text;
  final EdgeInsets? padding;
  final Function() onTap;
  final bool isEnable;
  final bool isLoading;
  final double? width;
  final double? height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isEnable && !isLoading) {
          onTap();
        }
      },
      child: Container(
        width: width,
        height: height,
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSizes.dimenToPx30,
              vertical: AppSizes.dimenToPx12,
            ),
        decoration: isEnable
            ? ShapeDecoration(
                gradient: AppColor.primaryGradient,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    borderRadius ?? AppSizes.dimenToPx8,
                  ),
                ),
                shadows: const [
                  BoxShadow(
                    color: AppColor.shadow,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              )
            : ShapeDecoration(
                color: colors.inputBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    borderRadius ?? AppSizes.dimenToPx8,
                  ),
                ),
              ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.onPrimaryColor,
                    ),
                  ),
                )
              : Text(
                  text,
                  style: ChatTextStyles.buttonText.copyWith(
                    color: isEnable
                        ? colors.onPrimaryColor
                        : colors.textLight,
                  ),
                ),
        ),
      ),
    );
  }
}
