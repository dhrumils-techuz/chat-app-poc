import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../widgets/avatar_widget.dart';
import 'group_info_controller.dart';
import 'widget/add_member_dialog.dart';
import 'widget/member_list_tile.dart';

class GroupInfoScreen extends GetView<GroupInfoController> {
  const GroupInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Group Info',
          style: ChatTextStyles.appBarTitle.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.members.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: colors.primaryColor),
          );
        }

        return ListView(
          children: [
            // Group header
            _buildGroupHeader(context, colors),

            const SizedBox(height: AppSizes.dimenToPx8),

            // Media / Links / Docs section (placeholder)
            _buildMediaSection(colors),

            const SizedBox(height: AppSizes.dimenToPx8),

            // Members section
            _buildMembersSection(context, colors),

            const SizedBox(height: AppSizes.dimenToPx8),

            // Leave group
            _buildLeaveGroup(colors),

            const SizedBox(height: AppSizes.dimenToPx32),
          ],
        );
      }),
    );
  }

  Widget _buildGroupHeader(BuildContext context, ChatColors colors) {
    return Container(
      color: colors.surfaceColor,
      padding: const EdgeInsets.all(AppSizes.dimenToPx24),
      child: Column(
        children: [
          // Group avatar
          Obx(() {
            final conv = controller.conversation.value;
            return Stack(
              children: [
                AvatarWidget(
                  imageUrl: conv.avatarUrl,
                  name: conv.displayName,
                  size: AppSizes.avatarExtraLarge,
                ),
                if (controller.isAdmin)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: AppSizes.dimenToPx28,
                      height: AppSizes.dimenToPx28,
                      decoration: BoxDecoration(
                        color: colors.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.surfaceColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: AppSizes.dimenToPx14,
                        color: colors.onPrimaryColor,
                      ),
                    ),
                  ),
              ],
            );
          }),

          const SizedBox(height: AppSizes.dimenToPx16),

          // Group name (editable if admin)
          Obx(() {
            if (controller.isEditingName.value) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.groupNameController,
                      textAlign: TextAlign.center,
                      style: ChatTextStyles.heading.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.dimenToPx8,
                          vertical: AppSizes.dimenToPx8,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: colors.primaryColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: colors.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.check, color: colors.primaryColor),
                    onPressed: controller.toggleEditName,
                  ),
                ],
              );
            }

            return GestureDetector(
              onTap: controller.isAdmin ? controller.toggleEditName : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      controller.conversation.value.displayName,
                      style: ChatTextStyles.heading.copyWith(
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (controller.isAdmin) ...[
                    const SizedBox(width: AppSizes.dimenToPx8),
                    Icon(
                      Icons.edit,
                      size: AppSizes.dimenToPx16,
                      color: colors.iconColor,
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: AppSizes.dimenToPx4),

          // Member count
          Obx(() => Text(
                '${controller.members.length} members',
                style: ChatTextStyles.small.copyWith(
                  color: colors.textSecondary,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMediaSection(ChatColors colors) {
    return Container(
      color: colors.surfaceColor,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.photo, color: colors.iconColor),
            title: Text(
              'Media, Links, and Docs',
              style: ChatTextStyles.body.copyWith(color: colors.textPrimary),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colors.iconColor,
            ),
            onTap: () {
              // Placeholder: navigate to media gallery
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, ChatColors colors) {
    return Container(
      color: colors.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.dimenToPx16,
              AppSizes.dimenToPx16,
              AppSizes.dimenToPx16,
              AppSizes.dimenToPx8,
            ),
            child: Obx(() => Text(
                  '${controller.members.length} members',
                  style: ChatTextStyles.smallSemiBold.copyWith(
                    color: colors.textSecondary,
                  ),
                )),
          ),

          // Add member button (if admin)
          Obx(() {
            if (!controller.isAdmin) return const SizedBox.shrink();
            return ListTile(
              leading: Container(
                width: AppSizes.avatarMedium,
                height: AppSizes.avatarMedium,
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add,
                  color: colors.primaryColor,
                ),
              ),
              title: Text(
                'Add Member',
                style: ChatTextStyles.bodySemiBold.copyWith(
                  color: colors.primaryColor,
                ),
              ),
              onTap: () => _showAddMemberDialog(context),
            );
          }),

          // Member list
          Obx(() => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.members.length,
                itemBuilder: (context, index) {
                  final member = controller.members[index];
                  return MemberListTile(
                    member: member,
                    isCurrentUserAdmin: controller.isAdmin,
                    isCurrentUser: member.userId == controller.currentUserId,
                    onLongPress: controller.isAdmin &&
                            member.userId != controller.currentUserId
                        ? () => controller.removeMember(member)
                        : null,
                  );
                },
              )),
        ],
      ),
    );
  }

  Widget _buildLeaveGroup(ChatColors colors) {
    return Container(
      color: colors.surfaceColor,
      child: ListTile(
        leading: Icon(Icons.exit_to_app, color: colors.errorColor),
        title: Text(
          'Leave Group',
          style: ChatTextStyles.bodySemiBold.copyWith(
            color: colors.errorColor,
          ),
        ),
        onTap: controller.leaveGroup,
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddMemberDialog(
        chatRepository: controller.chatRepository,
        existingMemberIds: controller.memberUserIds,
        onMemberSelected: controller.addMember,
      ),
    );
  }
}
