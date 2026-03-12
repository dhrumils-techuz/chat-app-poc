import 'package:bluebird_p2_project/reporting/core/theme/color.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../../core/values/app_strings.dart';
import '../../../../data/types/module_navigation_key.dart';
import '../../../../widgets/common_app_bar.dart';
import '../spend_analysis_detail_controller.dart';

class SpendAnalysisDetailView extends StatelessWidget {
  const SpendAnalysisDetailView({super.key, required this.controller});

  final SpendAnalysisDetailController controller;

  @override
  Widget build(BuildContext context) {
    AppColors myColor = AppColors.getInstance(context);
    return Column(
      children: [Text('Spendanalysis Detail')],
    );
  }
}
