import 'package:bluebird_p2_project/reporting/app/routes/call_analysis_navigator.dart';
import 'package:bluebird_p2_project/reporting/app/widgets/common_app_bar.dart';
import 'package:bluebird_p2_project/reporting/app/widgets/common_custom_dropdown.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../../core/theme/color.dart';
import '../../../../../core/values/app_sizes.dart';
import '../../../../../core/values/app_strings.dart';
import '../../../../data/types/module_navigation_key.dart';
import '../../../../routes/spend_analysis_navigator.dart';
import '../spend_analysis_controller.dart';

class SpendAnalysisView extends StatelessWidget {
  const SpendAnalysisView({super.key, required this.controller});

  final SpendAnalysisController controller;

  @override
  Widget build(BuildContext context) {
    AppColors myColor = AppColors.getInstance(context);
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: AppSizes.dimenToPx18,
            ),
            Obx(
              () => CommonCustomDropdown<String>(
                items: controller.lastMonthsSelectList,
                selectedValue: controller.selectLastMonths.value,
                onChanged: (value) {
                  controller.selectLastMonths.value = value.toString();
                },
                hint: Keys.Last_Months.tr,
                itemLabel: (value) {
                  return value.toString();
                },
              ),
            ),
            SizedBox(
              width: AppSizes.dimenToPx14,
            ),
            Obx(
              () => CommonCustomDropdown<String>(
                items: controller.saleRepList,
                selectedValue: controller.selectSaleRep.value,
                onChanged: (value) {
                  controller.selectSaleRep.value = value.toString();
                },
                hint: Keys.Select_Sale_Rep.tr,
                itemLabel: (value) {
                  return value.toString();
                },
              ),
            ),
            SizedBox(
              width: AppSizes.dimenToPx18,
            ),
          ],
        )
      ],
    );
  }
}
