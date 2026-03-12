import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/call_activity/call_activity_controller.dart';
import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/call_activity/widget/call_activity_view.dart';
import 'package:bluebird_p2_project/reporting/app/widgets/common_app_bar.dart';
import 'package:bluebird_p2_project/reporting/core/theme/color.dart';
import 'package:bluebird_p2_project/reporting/core/values/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CallActivityScreen extends StatelessWidget {
  const CallActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CallActivityController controller = Get.put(CallActivityController());
    final AppColors colors = AppColors.getInstance(context);

    return ColoredBox(
      color: colors.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            CommonAppBar(
              title: Keys.Call_Activity.tr,
              showHamburgerMenuIcon: true,
            ),
            Expanded(child: CallActivityView(controller: controller)),
          ],
        ),
      ),
    );
  }
}
