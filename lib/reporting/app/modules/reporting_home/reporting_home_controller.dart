import 'package:bluebird_p2_project/reporting/app/data/types/module_navigation_key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/values/app_images.dart';
import '../../../core/values/app_strings.dart';
import '../../routes/call_analysis_navigator.dart';
import '../../routes/spend_analysis_navigator.dart';

class ReportingHomeController extends GetxController {
  var selectedIndex = 1.obs;

  final routeList = [
    AppRouteItem(
        route: CallAnalysisRoutes.CALL_ANALYSIS,
        label: Keys.Call_Analysis.tr,
        iconUrl: AppImages.icCallAnalysis,
        nestedKeyId: ModuleNavigationKey.CALL_ANALYSIS,
        page: (_) {
          return CallAnalysisNavigator();
        }),
    AppRouteItem(
        route: SpendAnalysisRoutes.SPEND_ANALYSIS,
        label: Keys.Spend_Analysis.tr,
        iconUrl: AppImages.icSpendAnalysis,
        nestedKeyId: ModuleNavigationKey.SPEND_ANALYSIS,
        page: (_) {
          return SpendAnalysisNavigator();
        }),
  ];

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  void updateIndex(int index) {
    selectedIndex.value = index;
  }

  @override
  void onClose() {
    super.onClose();
  }
}

class AppRouteItem {
  final String route;
  final String label;
  final String iconUrl;
  final int nestedKeyId;
  final WidgetBuilder page; // or asset path

  AppRouteItem(
      {required this.route,
      required this.label,
      required this.iconUrl,
      required this.nestedKeyId,
      required this.page});
}
