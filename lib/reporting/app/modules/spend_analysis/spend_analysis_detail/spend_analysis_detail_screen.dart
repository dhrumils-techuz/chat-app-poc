import 'package:bluebird_p2_project/reporting/app/modules/spend_analysis/spend_analysis_detail/spend_analysis_detail_controller.dart';
import 'package:bluebird_p2_project/reporting/app/modules/spend_analysis/spend_analysis_detail/widget/spend_analysis_detail_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/values/app_strings.dart';
import '../../../data/types/module_navigation_key.dart';
import '../../../widgets/common_app_bar.dart';

class SpendAnalysisDetailScreen extends StatelessWidget {
  const SpendAnalysisDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SpendAnalysisDetailController controller = SpendAnalysisDetailController();
    AppColors myColor = AppColors.getInstance(context);
    return Container(
        color: myColor.surfaceColor,
        child: SafeArea(
          child: Column(
            children: [
              CommonAppBar(
                title: Keys.Details.tr,
                showBack: true,
                onBackTap: () {
                  Get.back(id: ModuleNavigationKey.SPEND_ANALYSIS);
                },
              ),
              SpendAnalysisDetailView(
                controller: controller,
              )
            ],
          ),
        ));
  }
}
