import 'package:bluebird_p2_project/reporting/app/data/types/module_navigation_key.dart';
import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/incompleted_calls/incompleted_calls_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InCompletedCallsView extends StatelessWidget {
  const InCompletedCallsView({super.key, required this.controller});

  final InCompletedCallsController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () {
          Get.back(id: ModuleNavigationKey.CALL_ANALYSIS);
        },
        child: Text(
          'InCompletedCallsView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
