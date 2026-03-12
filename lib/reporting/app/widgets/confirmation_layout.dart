import 'package:bluebird_p2_project/reporting/app/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/color.dart';
import '../../core/theme/text_style.dart';
import '../../core/values/app_sizes.dart';
import '../../core/values/app_strings.dart';

import 'bordered_button.dart';
import 'custom_divider.dart';

class ConfirmationLayout extends StatelessWidget {
  const ConfirmationLayout({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.onCancel,
    required this.btnPositiveText,
    required this.btnNavigation,
  });

  final String title;
  final String content;
  final String? btnPositiveText;
  final String? btnNavigation;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    AppColors myColors = AppColors.getInstance(context);
    return Container(
      width: AppSizes.dimenToPx400,
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
            Text(
              title,
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.dimenToPx16,
              ),
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: AppTextStyles.primaryTextRegularW400.copyWith(
                  color: myColors.colorOnSurface,
                  fontSize: AppTextSizes.text16,
                ),
              ),
            ),
            const SizedBox(
              height: AppSizes.dimenToPx44,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.dimenToPx16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      text: btnPositiveText ?? Keys.Yes.tr,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.dimenToPx14,
                        vertical: AppSizes.dimenToPx12,
                      ),
                      onTap: () {
                        onConfirm.call();
                      },
                    ),
                  ),
                  const SizedBox(
                    width: AppSizes.dimenToPx20,
                  ),
                  Expanded(
                    child: BorderedButton(
                      text: btnNavigation ?? Keys.No.tr,
                      onTap: () {
                        onCancel.call();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
