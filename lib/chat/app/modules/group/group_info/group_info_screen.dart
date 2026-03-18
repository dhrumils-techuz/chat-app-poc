import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../widgets/gradient_button.dart';
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
          Keys.Group_Info.tr,
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

          // Group name (tap to edit via bottom sheet if admin)
          Obx(() => GestureDetector(
            onTap: controller.isAdmin
                ? () => _showEditNameSheet(context, colors)
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    controller.conversation.value.displayNameFor(
                        controller.currentUserId),
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
          )),

          const SizedBox(height: AppSizes.dimenToPx4),

          // Member count
          Obx(() => Text(
                '${controller.members.length} ${Keys.Members.tr}',
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
              Keys.Media_Links_Docs.tr,
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
                  '${controller.members.length} ${Keys.Members.tr}',
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
                Keys.Add_Member.tr,
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
          Keys.Leave_Group.tr,
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

  void _showEditNameSheet(BuildContext context, ChatColors colors) {
    // Reset controller text to current name
    controller.groupNameController.text =
        controller.conversation.value.displayNameFor(controller.currentUserId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // allows sheet to resize with keyboard
      builder: (ctx) {
        final sheetColors = ChatColors.getInstance(ctx);
        return SafeArea(
          child: Padding(
            // Push above keyboard
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: sheetColors.surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: sheetColors.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    Keys.Edit_Group_Name.tr,
                    style: ChatTextStyles.heading.copyWith(
                      color: sheetColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Text field
                  TextField(
                    controller: controller.groupNameController,
                    autofocus: true,
                    maxLength: 50,
                    style: ChatTextStyles.body.copyWith(
                      color: sheetColors.textPrimary,
                    ),
                    cursorColor: sheetColors.primaryColor,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: sheetColors.inputBackgroundColor,
                      hintText: Keys.Group_Name.tr,
                      hintStyle: ChatTextStyles.body.copyWith(
                        color: sheetColors.textLight,
                      ),
                      counterStyle: ChatTextStyles.caption.copyWith(
                        color: sheetColors.textSecondary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: sheetColors.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Save button (full-width gradient)
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: Keys.Save.tr,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        controller.updateGroupName();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
