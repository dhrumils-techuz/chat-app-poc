import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/theme/color.dart';
import '../../core/theme/text_style.dart';
import '../../core/values/app_sizes.dart';
import 'custom_divider.dart';
import 'gradient_button.dart';

class SimpleMessage extends StatelessWidget {
  const SimpleMessage({
    super.key,
    this.title,
    required this.message,
    required this.onTap,
    required this.buttonText,
  });

  final String? title;
  final String message;
  final String buttonText;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    AppColors myColors = AppColors.getInstance(context);
    return Container(
      width: context.isTablet ? AppSizes.dimenToPx400 : double.infinity,
      decoration: ShapeDecoration(
        color: myColors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.dimenToPx16,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.dimenToPx30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((title?.isNotEmpty ?? false))
              Column(
                children: [
                  Text(
                    title!,
                    style: AppTextStyles.primaryTextSemiBoldW600.copyWith(
                      color: myColors.colorOnSurface,
                      fontSize: AppTextSizes.text18,
                    ),
                  ),
                  const SizedBox(
                    height: AppSizes.dimenToPx24,
                  ),
                  const CustomDivider(
                    height: AppSizes.dimenToPx1,
                  ),
                  const SizedBox(
                    height: AppSizes.dimenToPx44,
                  ),
                ],
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: AppSizes.dimenToPx350,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.dimenToPx16,
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.primaryTextRegularW400.copyWith(
                      color: myColors.colorOnSurface,
                      fontSize: AppTextSizes.text16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: AppSizes.dimenToPx44,
            ),
            SizedBox(
              width: AppSizes.dimenToPx172,
              height: AppSizes.dimenToPx46,
              child: GradientButton(
                text: buttonText,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
