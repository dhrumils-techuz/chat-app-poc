import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/incompleted_calls/widget/incompleted_calls_view.dart';
import 'package:bluebird_p2_project/reporting/app/widgets/common_app_bar.dart';
import 'package:bluebird_p2_project/reporting/core/theme/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'incompleted_calls_controller.dart';

class InCompletedCallsScreen extends StatelessWidget {
  const InCompletedCallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final InCompletedCallsController controller =
        Get.put(InCompletedCallsController());
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
              child: InCompletedCallsView(
                controller: controller,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
