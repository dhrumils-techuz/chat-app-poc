import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _allNotifications = true;
  bool _messageNotifications = true;
  bool _groupNotifications = true;
  bool _sound = true;
  bool _vibration = true;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitchTile(
            colors: colors,
            icon: Icons.notifications_rounded,
            title: Keys.All_Notifications.tr,
            subtitle: Keys.Enable_disable_notifications.tr,
            value: _allNotifications,
            onChanged: (value) {
              setState(() {
                _allNotifications = value;
                if (!value) {
                  _messageNotifications = false;
                  _groupNotifications = false;
                  _sound = false;
                  _vibration = false;
                }
              });
            },
          ),
          _buildDivider(colors),
          _buildSwitchTile(
            colors: colors,
            icon: Icons.chat_bubble_rounded,
            title: Keys.Message_Notifications.tr,
            subtitle: Keys.Notify_direct_messages.tr,
            value: _messageNotifications,
            onChanged: _allNotifications
                ? (value) => setState(() => _messageNotifications = value)
                : null,
          ),
          _buildDivider(colors),
          _buildSwitchTile(
            colors: colors,
            icon: Icons.group_rounded,
            title: Keys.Group_Notifications.tr,
            subtitle: Keys.Notify_group_messages.tr,
            value: _groupNotifications,
            onChanged: _allNotifications
                ? (value) => setState(() => _groupNotifications = value)
                : null,
          ),
          _buildDivider(colors),
          _buildSwitchTile(
            colors: colors,
            icon: Icons.volume_up_rounded,
            title: Keys.Sound.tr,
            subtitle: Keys.Play_sound.tr,
            value: _sound,
            onChanged: _allNotifications
                ? (value) => setState(() => _sound = value)
                : null,
          ),
          _buildDivider(colors),
          _buildSwitchTile(
            colors: colors,
            icon: Icons.vibration_rounded,
            title: Keys.Vibration.tr,
            subtitle: Keys.Vibrate_notifications.tr,
            value: _vibration,
            onChanged: _allNotifications
                ? (value) => setState(() => _vibration = value)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required ChatColors colors,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    final isEnabled = onChanged != null;

    return SwitchListTile(
      secondary: Icon(
        icon,
        color: isEnabled ? colors.primaryColor : colors.textLight,
        size: AppSizes.dimenToPx24,
      ),
      title: Text(
        title,
        style: ChatTextStyles.bodySemiBold.copyWith(
          color: isEnabled ? colors.textPrimary : colors.textLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: ChatTextStyles.caption.copyWith(
          color: colors.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: colors.primaryColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.dimenToPx16,
        vertical: AppSizes.dimenToPx4,
      ),
    );
  }

  Widget _buildDivider(ChatColors colors) {
    return Divider(
      height: AppSizes.dimenToPx1,
      thickness: AppSizes.dimenToPx1,
      color: colors.dividerColor,
      indent: AppSizes.dimenToPx56,
    );
  }
}
