import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/widgets/confirmation_layout.dart';
import '../../app/widgets/simple_message.dart';
import '../theme/color.dart';
import '../theme/text_style.dart';
import '../values/app_sizes.dart';
import '../values/app_strings.dart';

class DialogHelper {
  static showConfirmationDialog(
    String? title,
    String? message, {
    bool barrierDismissible = true,
    String? btnPositiveText,
    String? btnNavigation,
    Function()? onPositiveResponse,
  }) {
    if (title == null || title.isEmpty) {
      return;
    }
    if (message == null || message.isEmpty) {
      return;
    }
    BuildContext? buildContext = Get.context;
    if (buildContext == null) {
      return;
    }
    showAppStyledDialog(
      buildContext: buildContext,
      barrierDismissible: barrierDismissible,
      contentBuilder: (context) => ConfirmationLayout(
        title: title,
        content: message,
        btnPositiveText: btnPositiveText,
        btnNavigation: btnNavigation,
        onConfirm: () {
          Get.back();
          onPositiveResponse?.call();
        },
        onCancel: () {
          Get.back();
        },
      ),
    );
  }

  static showMessage(
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

  static showSimpleMessage(
    String? title,
    String? message, {
    bool barrierDismissible = true,
    Function()? onTap,
    String? buttonText,
  }) {
    if (message == null || message.isEmpty) {
      return;
    }
    BuildContext? buildContext = Get.context;
    if (buildContext == null) {
      return;
    }
    showAppStyledDialog(
      buildContext: buildContext,
      barrierDismissible: barrierDismissible,
      contentBuilder: (context) => SimpleMessage(
        title: title,
        message: message,
        buttonText: buttonText ?? Keys.OK.tr,
        onTap: () {
          Get.back();
          onTap?.call();
        },
      ),
    );
  }

  static showSimpleMessageWithTestMode(
    String title,
    String? message, {
    bool barrierDismissible = true,
    String? testModeMessage,
    Function()? onTap,
  }) {
    if (message == null || message.isEmpty) {
      return;
    }
    BuildContext? buildContext = Get.context;
    if (buildContext == null) {
      return;
    }
    showAppStyledDialog(
      buildContext: buildContext,
      barrierDismissible: barrierDismissible,
      contentBuilder: (context) => Container(
        decoration: ShapeDecoration(
          color: AppColors.getInstance(context).backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSizes.dimenToPx32,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SimpleMessage(
              title: title,
              message: message,
              onTap: () {
                //Navigator.pop(context);
                Get.back();
                onTap?.call();
              },
              buttonText: Keys.OK.tr,
            ),
            GestureDetector(
              onTap: () {
                // Navigator.pop(context);
                Get.back();
                showAppStyledDialog(
                  buildContext: buildContext,
                  barrierDismissible: barrierDismissible,
                  contentBuilder: (context) => Padding(
                    padding: const EdgeInsets.all(
                      AppSizes.dimenToPx24,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.dimenToPx30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              hintText: "Enter Password",
                            ),
                            onSubmitted: (value) {
                              // Navigator.pop(context);
                              Get.back();
                              if (value == "11997733") {
                                showSimpleMessage(
                                  title,
                                  testModeMessage,
                                  buttonText: Keys.Copy.tr,
                                  onTap: () async {
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text: testModeMessage ?? "",
                                      ),
                                    );
                                    onTap?.call();
                                  },
                                );
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Text(
                "Enter Test Mode",
                style: AppTextStyles.primaryTextMediumW500.copyWith(
                  color: AppColors.getInstance(context).primaryColor,
                  fontSize: AppTextSizes.text18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*static void showRescheduleEvent(
    String? title,
    String? message, {
    bool barrierDismissible = true,
    Function()? onPositiveResponse,
  }) {
    if (title == null || title.isEmpty) {
      return;
    }
    if (message == null || message.isEmpty) {
      return;
    }
    BuildContext? buildContext = Get.context;
    if (buildContext == null) {
      return;
    }
    showAppStyledDialog(
      buildContext: buildContext,
      barrierDismissible: barrierDismissible,
      contentBuilder: (context) => RescheduleMissedEventDialog(
        title: title,
        content: message,
        onConfirm: () {
          Get.back();
          onPositiveResponse?.call();
        },
      ),
    );
  }*/

  static void showAppStyledDialog({
    BuildContext? buildContext,
    bool barrierDismissible = true,
    required Widget Function(BuildContext) contentBuilder,
  }) {
    final context = buildContext ?? Get.context;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.dimenToPx16,
            vertical: AppSizes.dimenToPx24,
          ),
          child: contentBuilder(context),
        ),
      );
    }
  }
}
