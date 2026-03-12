import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../widgets/gradient_button.dart';
import 'sign_in_controller.dart';
import 'widget/email_password_form.dart';

class SignInScreen extends GetView<SignInController> {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.surfaceColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.dimenToPx24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.dimenToPx40),

                  // App title
                  _buildAppTitle(),

                  const SizedBox(height: AppSizes.dimenToPx8),

                  // Subtitle
                  Text(
                    'Sign in to continue',
                    style: ChatTextStyles.body.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSizes.dimenToPx48),

                  // Email & Password form
                  Obx(
                    () => EmailPasswordForm(
                      formKey: controller.formKey,
                      emailController: controller.emailController,
                      passwordController: controller.passwordController,
                      isPasswordVisible: controller.isPasswordVisible.value,
                      onTogglePasswordVisibility:
                          controller.togglePasswordVisibility,
                    ),
                  ),

                  const SizedBox(height: AppSizes.dimenToPx12),

                  // Error message
                  Obx(() => _buildErrorMessage(colors)),

                  const SizedBox(height: AppSizes.dimenToPx24),

                  // Sign In button
                  Obx(
                    () => GradientButton(
                      text: 'Sign In',
                      onTap: controller.login,
                      isLoading: controller.isLoading.value,
                      isEnable: !controller.isLoading.value &&
                          !controller.isLockedOut,
                      height: AppSizes.inputBarHeight,
                      borderRadius: AppSizes.dimenToPx12,
                    ),
                  ),

                  const SizedBox(height: AppSizes.dimenToPx40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return Text(
      'WhatsUp',
      style: ChatTextStyles.title.copyWith(
        color: AppColor.primary,
        fontSize: 32,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage(ChatColors colors) {
    final error = controller.errorMessage.value;
    if (error == null || error.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.dimenToPx12,
        vertical: AppSizes.dimenToPx10,
      ),
      decoration: BoxDecoration(
        color: colors.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.dimenToPx8),
        border: Border.all(
          color: colors.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colors.errorColor,
            size: 18,
          ),
          const SizedBox(width: AppSizes.dimenToPx8),
          Expanded(
            child: Text(
              error,
              style: ChatTextStyles.small.copyWith(
                color: colors.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
