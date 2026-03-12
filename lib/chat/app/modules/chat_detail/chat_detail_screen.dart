import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/screen_util.dart';
import 'chat_detail_controller.dart';
import 'widget/chat_detail_view_desktop.dart';
import 'widget/chat_detail_view_mobile.dart';

class ChatDetailScreen extends GetView<ChatDetailController> {
  const ChatDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = ScreenUtil.width(context);

    if (screenWidth >= 600) {
      return const ChatDetailViewDesktop();
    }

    return const ChatDetailViewMobile();
  }
}
