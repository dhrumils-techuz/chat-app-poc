import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/completed_calls/completed_calls_controller.dart';
import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/completed_calls/widget/completed_calls_view.dart';
import 'package:bluebird_p2_project/reporting/app/widgets/common_app_bar.dart';
import 'package:bluebird_p2_project/reporting/core/theme/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompletedCallsScreen extends StatelessWidget {
  const CompletedCallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CompletedCallsController controller =
        Get.put(CompletedCallsController());
    AppColors myColor = AppColors.getInstance(context);
    return Container(
      color: myColor.secondaryContainer,
      child: SafeArea(
        child: Column(
          children: [
            CommonAppBar(
              title: "",
            ),
            Expanded(
              child: CompletedCallsView(
                controller: controller,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
