import 'package:bluebird_p2_project/reporting/app/data/repository/spend_analysis_repository.dart';
import 'package:bluebird_p2_project/reporting/app/data/service/spend_analysis/dio_spend_analysis_service.dart';
import 'package:bluebird_p2_project/reporting/app/modules/spend_analysis/spend_analysis/spend_analysis_controller.dart';
import 'package:bluebird_p2_project/reporting/app/modules/spend_analysis/spend_analysis/widget/spend_analysis_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/values/app_strings.dart';
import '../../../data/types/module_navigation_key.dart';
import '../../../routes/spend_analysis_navigator.dart';
import '../../../widgets/common_app_bar.dart';

class SpendAnalysisScreen extends StatelessWidget {
  const SpendAnalysisScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final SpendAnalysisController controller = Get.put(SpendAnalysisController(
        spendAnalysisRepository: SpendAnalysisRepository(
            spendAnalysisService:
                DioSpendAnalysisService(dioRemoteApiClient: Get.find()))));
    AppColors myColor = AppColors.getInstance(context);
    return Container(
        color: myColor.secondaryContainer,
        child: SafeArea(
          child: Column(
            children: [
              CommonAppBar(
                title: Keys.Spend_Analysis.tr,
                showHamburgerMenuIcon: true,
              ),
              SpendAnalysisView(controller: controller),
            ],
          ),
        ));
  }
}
