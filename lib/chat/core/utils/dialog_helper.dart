import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/color.dart';
import '../theme/text_style.dart';
import '../values/app_sizes.dart';
import '../values/app_strings.dart';

class DialogHelper {
  static void showConfirmationDialog(
    String? title,
    String? message, {
    bool barrierDismissible = true,
    String? btnPositiveText,
    String? btnNegativeText,
    Function()? onPositiveResponse,
    Function()? onNegativeResponse,
  }) {
    if (title == null || title.isEmpty) return;
    if (message == null || message.isEmpty) return;

    final context = Get.context;
    if (context == null) return;

    showAppStyledDialog(
      buildContext: context,
      barrierDismissible: barrierDismissible,
      contentBuilder: (ctx) {
        final colors = ChatColors.getInstance(ctx);
        return Container(
          padding: const EdgeInsets.all(AppSizes.dimenToPx24),
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.dimenToPx16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: ChatTextStyles.heading.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.dimenToPx12),
              Text(
                message,
                style: ChatTextStyles.body.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.dimenToPx24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onNegativeResponse?.call();
                      },
                      child: Text(
                        btnNegativeText ?? Keys.No.tr,
                        style: ChatTextStyles.buttonText.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.dimenToPx12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onPositiveResponse?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryColor,
                        foregroundColor: colors.onPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.dimenToPx8),
                        ),
                      ),
                      child: Text(
                        btnPositiveText ?? Keys.Yes.tr,
                        style: ChatTextStyles.buttonText.copyWith(
                          color: colors.onPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static void showMessage(
    String? message, {
    bool barrierDismissible = true,
    Function()? onTap,
    String? buttonText,
  }) {
    showSimpleMessage(
      null,
      message,
      onTap: onTap,
      buttonText: buttonText,
      barrierDismissible: barrierDismissible,
    );
  }

  static void showSimpleMessage(
    String? title,
    String? message, {
    bool barrierDismissible = true,
    Function()? onTap,
    String? buttonText,
  }) {
    if (message == null || message.isEmpty) return;

    final context = Get.context;
    if (context == null) return;

    showAppStyledDialog(
      buildContext: context,
      barrierDismissible: barrierDismissible,
      contentBuilder: (ctx) {
        final colors = ChatColors.getInstance(ctx);
        return Container(
          padding: const EdgeInsets.all(AppSizes.dimenToPx24),
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.dimenToPx16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null && title.isNotEmpty) ...[
                Text(
                  title,
                  style: ChatTextStyles.heading.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.dimenToPx12),
              ],
              Text(
                message,
                style: ChatTextStyles.body.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.dimenToPx24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onTap?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    foregroundColor: colors.onPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.dimenToPx8),
                    ),
                  ),
                  child: Text(
                    buttonText ?? Keys.OK.tr,
                    style: ChatTextStyles.buttonText.copyWith(
                      color: colors.onPrimaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showAppStyledDialog({
    BuildContext? buildContext,
    bool barrierDismissible = true,
    required Widget Function(BuildContext) contentBuilder,
  }) {
    // Prefer the overlay context (guaranteed to have an Overlay ancestor)
    // over a generic Get.context which may not have one.
    final context = buildContext ?? Get.overlayContext ?? Get.context;
    if (context == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.dimenToPx16,
            vertical: AppSizes.dimenToPx24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.dimenToPx16),
          ),
          child: contentBuilder(context),
        ),
      );
    } catch (_) {
      // Overlay not available — silently ignore
    }
  }

  /// Returns true if the GetX overlay is available for showing snackbars/dialogs.
  static bool get _isOverlayAvailable {
    try {
      return Get.overlayContext != null;
    } catch (_) {
      return false;
    }
  }

  static void showSnackBar(
    String title,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!_isOverlayAvailable) return;
    try {
      Get.snackbar(
        title,
        message,
        colorText: textColor ?? AppColor.white,
        backgroundColor: backgroundColor ?? AppColor.primary,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(AppSizes.dimenToPx16),
        borderRadius: AppSizes.dimenToPx8,
        duration: duration,
      );
    } catch (_) {
      // Overlay not available — silently ignore
    }
  }
}
