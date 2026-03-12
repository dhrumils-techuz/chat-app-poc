import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/call_activity/call_activity_controller.dart';
import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/call_activity/trend/call_activity_trend_tab_view.dart';
import 'package:bluebird_p2_project/reporting/app/widgets/common_tab_widget.dart';
import 'package:bluebird_p2_project/reporting/core/theme/color.dart';
import 'package:bluebird_p2_project/reporting/core/theme/text_style.dart';
import 'package:bluebird_p2_project/reporting/core/values/app_sizes.dart';
import 'package:bluebird_p2_project/reporting/core/values/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CallActivityView extends StatelessWidget {
  final CallActivityController controller;

  const CallActivityView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.getInstance(context);

    return Obx(() {
      return CommonTabWidget(
        selectedTab: controller.selectedTab.value,
        tabNames: [Keys.Metrics.tr, Keys.Trend.tr],
        onTabChange: controller.onTabChange,
        tabChildren: [
          Center(
            child: Text(
              Keys.Metrics.tr,
              style: AppTextStyles.primaryTextRegularW400.copyWith(
                fontSize: AppTextSizes.text16,
                color: colors.primaryColor,
              ),
            ),
          ),
          CallActivityTrendTabView(controller: controller),
        ],
      );
    });
  }
}
