import 'package:flutter/material.dart';

import '../../../../../core/theme/color.dart';
import '../../../../../core/theme/text_style.dart';
import '../../../../../core/values/app_sizes.dart';
import '../../../../data/model/group_member_model.dart';
import '../../../../widgets/avatar_widget.dart';

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.member,
    required this.isCurrentUserAdmin,
    required this.isCurrentUser,
    this.onLongPress,
  });

  final GroupMemberModel member;
  final bool isCurrentUserAdmin;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return ListTile(
      onLongPress: onLongPress,
      leading: AvatarWidget(
        imageUrl: member.avatarUrl,
        name: member.name,
        size: AppSizes.avatarMedium,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.name,
              style: ChatTextStyles.bodySemiBold.copyWith(
                color: colors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: AppSizes.dimenToPx6),
            Text(
              '(You)',
              style: ChatTextStyles.small.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      subtitle: member.isAdmin
          ? null
          : Text(
              'Member',
              style: ChatTextStyles.small.copyWith(
                color: colors.textSecondary,
              ),
            ),
      trailing: member.isAdmin
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.dimenToPx10,
                vertical: AppSizes.dimenToPx4,
              ),
              decoration: BoxDecoration(
                color: colors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
              ),
              child: Text(
                'Admin',
                style: ChatTextStyles.caption.copyWith(
                  color: colors.primaryColor,
                ),
              ),
            )
          : null,
    );
  }
}
