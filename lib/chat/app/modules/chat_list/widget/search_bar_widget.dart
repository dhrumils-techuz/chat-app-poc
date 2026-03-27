import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../chat_list_controller.dart';

class ChatSearchBarWidget extends GetView<ChatListController> {
  const ChatSearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Container(
      height: AppSizes.dimenToPx40,
      decoration: BoxDecoration(
        color: colors.inputBackgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.dimenToPx12),
      ),
      child: Obx(() {
        final hasText = controller.searchQuery.value.isNotEmpty;

        return TextField(
          onChanged: controller.searchConversations,
          style: ChatTextStyles.body.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: Keys.Search_conversations.tr,
            hintStyle: ChatTextStyles.body.copyWith(
              color: colors.textTimestamp,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colors.iconColor,
              size: AppSizes.dimenToPx20,
            ),
            suffixIcon: hasText
                ? IconButton(
                    onPressed: () {
                      controller.searchConversations('');
                      FocusScope.of(context).unfocus();
                    },
                    icon: Icon(
                      Icons.close,
                      color: colors.iconColor,
                      size: AppSizes.dimenToPx18,
                    ),
                    splashRadius: 16,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppSizes.dimenToPx10,
            ),
          ),
        );
      }),
    );
  }
}
