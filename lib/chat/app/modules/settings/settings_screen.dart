import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_strings.dart';
import '../../../core/theme/color.dart';
import '../../../core/theme/text_style.dart';
import '../../../core/theme/theme_controller.dart';
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
      body: SafeArea(
        top: false,
        child: Center(
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

              // Theme
              Container(
                color: colors.surfaceColor,
                child: ListTile(
                  leading: Icon(
                    Icons.palette_outlined,
                    color: colors.iconColor,
                  ),
                  title: Text(
                    Keys.Theme.tr,
                    style: ChatTextStyles.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Obx(() {
                    final themeCtrl = Get.find<ThemeController>();
                    final label = _themeModeLabel(themeCtrl.themeMode.value);
                    return Text(
                      label,
                      style: ChatTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    );
                  }),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.iconColor,
                  ),
                  onTap: () => _showThemeDialog(context, colors),
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
      )),
    );
  }

  String _themeModeLabel(String mode) {
    switch (mode) {
      case 'light':
        return Keys.Light.tr;
      case 'dark':
        return Keys.Dark.tr;
      default:
        return Keys.System_Default.tr;
    }
  }

  void _showThemeDialog(BuildContext context, ChatColors colors) {
    final themeCtrl = Get.find<ThemeController>();
    final selected = themeCtrl.themeMode.value.obs;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: colors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.dimenToPx16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.dimenToPx24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Keys.Choose_Theme.tr,
                  style: ChatTextStyles.heading.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.dimenToPx16),
                Obx(() => _buildThemeOption(
                      colors,
                      label: Keys.Light.tr,
                      value: 'light',
                      icon: Icons.light_mode_outlined,
                      selected: selected,
                    )),
                Obx(() => _buildThemeOption(
                      colors,
                      label: Keys.Dark.tr,
                      value: 'dark',
                      icon: Icons.dark_mode_outlined,
                      selected: selected,
                    )),
                Obx(() => _buildThemeOption(
                      colors,
                      label: Keys.System_Default.tr,
                      value: 'system',
                      icon: Icons.settings_suggest_outlined,
                      selected: selected,
                    )),
                const SizedBox(height: AppSizes.dimenToPx16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        Keys.Cancel.tr,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: AppSizes.dimenToPx8),
                    ElevatedButton(
                      onPressed: () {
                        themeCtrl.setThemeMode(selected.value);
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryColor,
                        foregroundColor: colors.onPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.dimenToPx8),
                        ),
                      ),
                      child: Text(Keys.OK.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    ChatColors colors, {
    required String label,
    required String value,
    required IconData icon,
    required RxString selected,
  }) {
    final isSelected = selected.value == value;
    return InkWell(
      onTap: () => selected.value = value,
      borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.dimenToPx12,
          vertical: AppSizes.dimenToPx12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryColor.withValues(alpha: 0.08)
              : null,
          borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
          border: isSelected
              ? Border.all(color: colors.primaryColor, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colors.primaryColor : colors.iconColor,
              size: 22,
            ),
            const SizedBox(width: AppSizes.dimenToPx12),
            Expanded(
              child: Text(
                label,
                style: ChatTextStyles.body.copyWith(
                  color: isSelected ? colors.primaryColor : colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colors.primaryColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
