import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/completed_calls/completed_calls_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/types/module_navigation_key.dart';
import '../../../../routes/call_analysis_navigator.dart';

class CompletedCallsView extends StatelessWidget {
  const CompletedCallsView({super.key, required this.controller});

  final CompletedCallsController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () {
          Get.toNamed(CallAnalysisRoutes.INCOMPLETED_CALL,
              id: ModuleNavigationKey.CALL_ANALYSIS);
        },
        child: Text(
          'CompletedCallsView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
