import 'package:bluebird_p2_project/reporting/app/modules/reporting_home/reporting_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:bluebird_p2_project/reporting/app/modules/reporting_home/widget/reporting_home_view.dart';

class ReportingHomeScreen extends StatelessWidget {
  const ReportingHomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ReportingHomeController controller =
        Get.put(ReportingHomeController());
    return ReportingHomeView(
      controller: controller,
    );
  }
}
