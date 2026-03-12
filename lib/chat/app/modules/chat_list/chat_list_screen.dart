import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/screen_util.dart';
import 'chat_list_controller.dart';
import 'widget/chat_list_view_desktop.dart';
import 'widget/chat_list_view_mobile.dart';

class ChatListScreen extends GetView<ChatListController> {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = ScreenUtil.width(context);

    if (screenWidth >= 600) {
      return const ChatListViewDesktop();
    }

    return const ChatListViewMobile();
  }
}
