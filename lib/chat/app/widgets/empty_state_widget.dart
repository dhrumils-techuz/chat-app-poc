import 'package:flutter/material.dart';

import '../../core/theme/color.dart';
import '../../core/theme/text_style.dart';
import '../../core/values/app_sizes.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imagePath,
    this.actionText,
    this.onAction,
    this.iconSize = 80,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imagePath;
  final String? actionText;
  final VoidCallback? onAction;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.dimenToPx32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null) ...[
              Image.asset(
                imagePath!,
                width: iconSize * 2,
                height: iconSize * 2,
              ),
              const SizedBox(height: AppSizes.dimenToPx24),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: colors.textLight,
              ),
              const SizedBox(height: AppSizes.dimenToPx24),
            ],
            Text(
              title,
              style: ChatTextStyles.heading.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.dimenToPx8),
              Text(
                subtitle!,
                style: ChatTextStyles.body.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSizes.dimenToPx24),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: colors.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.dimenToPx24,
                    vertical: AppSizes.dimenToPx12,
                  ),
                ),
                child: Text(
                  actionText!,
                  style: ChatTextStyles.buttonText.copyWith(
                    color: colors.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
