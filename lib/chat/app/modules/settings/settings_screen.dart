import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_strings.dart';
import '../../../core/theme/color.dart';
import '../../../core/theme/text_style.dart';
import '../../../core/values/app_sizes.dart';
import '../../routes/app_pages.dart';
import 'settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

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
          Keys.Settings.tr,
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
              const SizedBox(height: AppSizes.dimenToPx8),

              // Profile row
              Container(
                color: colors.surfaceColor,
                child: ListTile(
                  leading: Icon(Icons.person_outline,
                      color: colors.iconColor),
                  title: Text(
                    Keys.Profile.tr,
                    style: ChatTextStyles.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      color: colors.iconColor),
                  onTap: () => Get.toNamed(ChatAppRoutes.PROFILE),
                ),
              ),

              const SizedBox(height: AppSizes.dimenToPx8),

              Container(
                color: colors.surfaceColor,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.notifications_outlined,
                          color: colors.iconColor),
                      title: Text(
                        Keys.Notifications.tr,
                        style: ChatTextStyles.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right,
                          color: colors.iconColor),
                      onTap: () {},
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: AppSizes.dimenToPx56),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: colors.dividerColor,
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.lock_outline,
                          color: colors.iconColor),
                      title: Text(
                        Keys.Privacy.tr,
                        style: ChatTextStyles.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right,
                          color: colors.iconColor),
                      onTap: () {},
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: AppSizes.dimenToPx56),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: colors.dividerColor,
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.storage_outlined,
                          color: colors.iconColor),
                      title: Text(
                        Keys.Storage_and_Data.tr,
                        style: ChatTextStyles.body.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right,
                          color: colors.iconColor),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.dimenToPx8),

              Container(
                color: colors.surfaceColor,
                child: Obx(() => ListTile(
                      leading:
                          Icon(Icons.logout, color: colors.errorColor),
                      title: Text(
                        Keys.Logout.tr,
                        style: ChatTextStyles.bodySemiBold.copyWith(
                          color: colors.errorColor,
                        ),
                      ),
                      enabled: !controller.isLoggingOut.value,
                      onTap: controller.logout,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
