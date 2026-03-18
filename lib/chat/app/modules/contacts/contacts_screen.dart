import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_strings.dart';
import '../../../core/theme/color.dart';
import '../../../core/theme/text_style.dart';
import '../../../core/values/app_sizes.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'contacts_controller.dart';

class ContactsScreen extends GetView<ContactsController> {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.surfaceColor,
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
          Keys.New_Chat.tr,
          style: ChatTextStyles.appBarTitle.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.dimenToPx16,
                  vertical: AppSizes.dimenToPx8,
                ),
                child: TextField(
                  onChanged: controller.onSearchChanged,
                  style: ChatTextStyles.body.copyWith(
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: Keys.Search_contacts.tr,
                    hintStyle: ChatTextStyles.body.copyWith(
                      color: colors.textLight,
                    ),
                    filled: true,
                    fillColor: colors.inputBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.dimenToPx12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.dimenToPx16,
                      vertical: AppSizes.dimenToPx14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colors.iconColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colors.primaryColor,
                      ),
                    );
                  }

                  final results = controller.searchResults;
                  if (results.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.person_search_outlined,
                      title: controller.searchQuery.value.isNotEmpty
                          ? Keys.No_users_found.tr
                          : Keys.Search_for_contacts.tr,
                      subtitle: controller.searchQuery.value.isNotEmpty
                          ? Keys.Try_different_search.tr
                          : Keys.Search_for_users.tr,
                    );
                  }

                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(
                        left: AppSizes.dimenToPx80,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: colors.dividerColor,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final user = results[index];
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
                        subtitle: Text(
                          user.email,
                          style: ChatTextStyles.small.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        onTap: () => controller.startConversation(user),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
