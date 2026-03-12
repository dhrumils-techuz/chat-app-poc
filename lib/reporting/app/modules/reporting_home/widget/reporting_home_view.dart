import 'package:bluebird_p2_project/reporting/app/modules/spend_analysis/spend_analysis/spend_analysis_screen.dart';
import 'package:bluebird_p2_project/reporting/app/modules/spend_analysis/spend_analysis/widget/spend_analysis_view.dart';
import 'package:bluebird_p2_project/reporting/app/modules/spend_analysis/spend_analysis_detail/spend_analysis_detail_screen.dart';
import 'package:bluebird_p2_project/reporting/core/utils/screen_util.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../core/values/app_sizes.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/responsive_drawer_widget.dart';
import '../reporting_home_controller.dart';

class ReportingHomeView extends StatelessWidget {
  const ReportingHomeView({
    super.key,
    required this.controller,
  });

  final ReportingHomeController controller;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final nestedNav = Get.nestedKey(controller
                  .routeList[controller.selectedIndex.value].nestedKeyId)
              ?.currentState;

          if (nestedNav != null && nestedNav.canPop()) {
            nestedNav.pop(); // pop inner screen
          } else {
            // No more nested back stack, now exit app
            SystemNavigator.pop(); // exits the app
            // OR: use exit(0); (less recommended)
          }
        }
      },
      child: Obx(
        () => ResponsiveDrawerWidget(
            menuWidth: ScreenUtil.isMobileDevice
                ? AppSizes.dimenToPx300
                : AppSizes.dimenToPx250,
            menu: AppDrawer(
              routeItems: controller.routeList,
              selectIndex: controller.selectedIndex.value,
              onItemTap: (index) {
                if (ScreenUtil.isMobileDevice &&
                    ScreenUtil.isPortrait(context)) {
                  Navigator.pop(context);
                }
                controller.updateIndex(index);
              },
            ),
            content: controller.routeList[controller.selectedIndex.value]
                .page(context)),
      ),
    );
  }
}
