import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/call_activity/call_activity_controller.dart';
import 'package:bluebird_p2_project/reporting/app/widgets/common_custom_dropdown.dart';
import 'package:bluebird_p2_project/reporting/core/values/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CallActivityTrendTabView extends StatelessWidget {
  final CallActivityController controller;

  const CallActivityTrendTabView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () => CommonCustomDropdown<String>(
            items: controller.lastMonthsSelectList,
            selectedValue: controller.selectLastMonths.value,
            onChanged: (value) {
              controller.selectLastMonths.value = value.toString();
            },
            hint: Keys.Last_Months.tr,
            itemLabel: (value) => value.toString(),
          ),
        ),
      ],
    );
  }
}
