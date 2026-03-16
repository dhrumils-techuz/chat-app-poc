import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/values/app_strings.dart';
import '../../../../../core/theme/color.dart';
import '../../../../../core/theme/text_style.dart';
import '../../../../../core/values/app_sizes.dart';

class EmailPasswordForm extends StatelessWidget {
  const EmailPasswordForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.onTogglePasswordVisibility,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final VoidCallback onTogglePasswordVisibility;

  static final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
  );

  /// HIPAA-compliant password validation:
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one digit
  /// - At least one special character
  static final _uppercaseRegExp = RegExp(r'[A-Z]');
  static final _lowercaseRegExp = RegExp(r'[a-z]');
  static final _digitRegExp = RegExp(r'[0-9]');
  static final _specialCharRegExp = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;/`~]');

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            style: ChatTextStyles.body.copyWith(
              color: colors.textPrimary,
            ),
            decoration: _buildInputDecoration(
              context: context,
              hintText: Keys.Email_address.tr,
              prefixIcon: Icons.email_outlined,
            ),
            validator: _validateEmail,
          ),

          const SizedBox(height: AppSizes.dimenToPx16),

          // Password field
          TextFormField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            style: ChatTextStyles.body.copyWith(
              color: colors.textPrimary,
            ),
            decoration: _buildInputDecoration(
              context: context,
              hintText: Keys.Password.tr,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: onTogglePasswordVisibility,
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.iconColor,
                  size: 20,
                ),
              ),
            ),
            validator: _validatePassword,
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final colors = ChatColors.getInstance(context);

    return InputDecoration(
      hintText: hintText,
      hintStyle: ChatTextStyles.body.copyWith(
        color: colors.textLight,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: colors.iconColor,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colors.inputBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.dimenToPx16,
        vertical: AppSizes.dimenToPx14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
        borderSide: const BorderSide(
          color: AppColor.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
        borderSide: const BorderSide(
          color: AppColor.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
        borderSide: const BorderSide(
          color: AppColor.error,
          width: 1.5,
        ),
      ),
      errorStyle: ChatTextStyles.caption.copyWith(
        color: AppColor.error,
      ),
      errorMaxLines: 3,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Keys.Email_is_required.tr;
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return Keys.Enter_valid_email.tr;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return Keys.Password_is_required.tr;
    }
    if (value.length < 8) {
      return Keys.Password_min_length.tr;
    }
    if (!_uppercaseRegExp.hasMatch(value)) {
      return Keys.Password_uppercase.tr;
    }
    if (!_lowercaseRegExp.hasMatch(value)) {
      return Keys.Password_lowercase.tr;
    }
    if (!_digitRegExp.hasMatch(value)) {
      return Keys.Password_number.tr;
    }
    if (!_specialCharRegExp.hasMatch(value)) {
      return Keys.Password_special_char.tr;
    }
    return null;
  }
}
