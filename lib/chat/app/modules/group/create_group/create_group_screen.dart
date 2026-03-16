import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../widgets/gradient_button.dart';
import 'create_group_controller.dart';

class CreateGroupScreen extends GetView<CreateGroupController> {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.surfaceColor,
      appBar: AppBar(
        backgroundColor: colors.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          Keys.New_Group.tr,
          style: ChatTextStyles.appBarTitle.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Group name input
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.dimenToPx16,
              vertical: AppSizes.dimenToPx12,
            ),
            child: TextField(
              controller: controller.groupNameController,
              style: ChatTextStyles.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: Keys.Group_name.tr,
                hintStyle: ChatTextStyles.body.copyWith(
                  color: colors.textLight,
                ),
                filled: true,
                fillColor: colors.inputBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.dimenToPx16,
                  vertical: AppSizes.dimenToPx14,
                ),
                prefixIcon: Icon(
                  Icons.group,
                  color: colors.primaryColor,
                ),
              ),
            ),
          ),

          // Selected members chips
          Obx(() {
            if (controller.selectedMembers.isEmpty) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              height: AppSizes.dimenToPx80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.dimenToPx16,
                ),
                itemCount: controller.selectedMembers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSizes.dimenToPx8),
                itemBuilder: (context, index) {
                  final member = controller.selectedMembers[index];
                  return _SelectedMemberChip(
                    member: member,
                    onRemove: () => controller.removeMember(member),
                  );
                },
              ),
            );
          }),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.dimenToPx16,
              vertical: AppSizes.dimenToPx8,
            ),
            child: TextField(
              onChanged: controller.onSearchChanged,
              style: ChatTextStyles.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: Keys.Search_users.tr,
                hintStyle: ChatTextStyles.small.copyWith(
                  color: colors.textLight,
                ),
                filled: true,
                fillColor: colors.inputBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.dimenToPx16,
                  vertical: AppSizes.dimenToPx10,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colors.iconColor,
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Search results
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: colors.primaryColor,
                  ),
                );
              }

              if (controller.searchQuery.value.isNotEmpty &&
                  controller.searchResults.isEmpty) {
                return Center(
                  child: Text(
                    Keys.No_users_found.tr,
                    style: ChatTextStyles.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.searchResults.length,
                itemBuilder: (context, index) {
                  final user = controller.searchResults[index];
                  return Obx(() {
                    final isSelected =
                        controller.isMemberSelected(user.id);
                    return ListTile(
                      leading: AvatarWidget(
                        imageUrl: user.avatarUrl,
                        name: user.name,
                        size: AppSizes.avatarMedium,
                      ),
                      title: Text(
                        user.name,
                        style: ChatTextStyles.bodySemiBold.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      subtitle: user.designation != null
                          ? Text(
                              user.designation!,
                              style: ChatTextStyles.small.copyWith(
                                color: colors.textSecondary,
                              ),
                            )
                          : null,
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) => controller.toggleMember(user),
                        activeColor: colors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.dimenToPx4),
                        ),
                      ),
                      onTap: () => controller.toggleMember(user),
                    );
                  });
                },
              );
            }),
          ),

          // Create button
          Obx(() {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.dimenToPx16),
                child: SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: Keys.Create_Group.tr,
                    onTap: controller.createGroup,
                    isEnable: controller.isValid,
                    isLoading: controller.isCreating.value,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SelectedMemberChip extends StatelessWidget {
  const _SelectedMemberChip({
    required this.member,
    required this.onRemove,
  });

  final dynamic member;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            AvatarWidget(
              imageUrl: member.avatarUrl,
              name: member.name,
              size: AppSizes.avatarMedium,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: AppSizes.dimenToPx18,
                  height: AppSizes.dimenToPx18,
                  decoration: BoxDecoration(
                    color: colors.errorColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: AppSizes.dimenToPx12,
                    color: colors.onPrimaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.dimenToPx4),
        SizedBox(
          width: AppSizes.dimenToPx56,
          child: Text(
            member.name,
            style: ChatTextStyles.caption.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
