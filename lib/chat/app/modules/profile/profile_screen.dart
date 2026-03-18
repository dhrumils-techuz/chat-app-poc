import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_strings.dart';
import '../../../core/theme/color.dart';
import '../../../core/theme/text_style.dart';
import '../../../core/values/app_sizes.dart';
import '../../widgets/avatar_widget.dart';
import 'profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);
    final user = controller.currentUser;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.surfaceColor,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          Keys.Profile.tr,
          style: ChatTextStyles.appBarTitle.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              // Avatar header section
              Container(
                color: colors.surfaceColor,
                padding: const EdgeInsets.all(AppSizes.dimenToPx24),
                child: Column(
                  children: [
                    AvatarWidget(
                      imageUrl: user?.avatarUrl,
                      name: user?.name ?? '?',
                      size: AppSizes.avatarExtraLarge,
                    ),
                    const SizedBox(height: AppSizes.dimenToPx16),
                    Text(
                      user?.name ?? Keys.Unknown.tr,
                      style: ChatTextStyles.heading.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.dimenToPx4),
                    Text(
                      user?.email ?? '',
                      style: ChatTextStyles.small.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (user?.designation != null) ...[
                      const SizedBox(height: AppSizes.dimenToPx4),
                      Text(
                        user!.designation!,
                        style: ChatTextStyles.small.copyWith(
                          color: colors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
