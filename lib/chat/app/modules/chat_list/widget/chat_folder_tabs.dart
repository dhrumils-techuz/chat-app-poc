import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../chat_list_controller.dart';

class ChatFolderTabs extends GetView<ChatListController> {
  const ChatFolderTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return SizedBox(
      height: AppSizes.dimenToPx44,
      child: Obx(() {
        final folderCount = controller.folders.length;
        final selectedIndex = controller.selectedFolderIndex.value;

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.dimenToPx12,
          ),
          itemCount: folderCount + 1, // +1 for "All" tab
          itemBuilder: (context, index) {
            final isSelected = selectedIndex == index;
            final label = index == 0 ? 'All' : controller.folders[index - 1].name;

            return GestureDetector(
              onTap: () => controller.onFolderTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.dimenToPx16,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      label,
                      style: isSelected
                          ? ChatTextStyles.bodySemiBold.copyWith(
                              color: colors.primaryColor,
                            )
                          : ChatTextStyles.body.copyWith(
                              color: AppColor.grey5,
                            ),
                    ),
                    const Spacer(),
                    // Underline indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: AppSizes.dimenToPx3,
                      width: isSelected ? AppSizes.dimenToPx24 : 0,
                      decoration: BoxDecoration(
                        gradient:
                            isSelected ? AppColor.primaryGradient : null,
                        borderRadius:
                            BorderRadius.circular(AppSizes.dimenToPx2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
