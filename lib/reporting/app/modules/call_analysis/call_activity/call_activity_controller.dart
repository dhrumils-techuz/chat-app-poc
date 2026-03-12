import 'package:bluebird_p2_project/reporting/core/values/app_strings.dart';
import 'package:get/get.dart';

class CallActivityController extends GetxController {
  RxString selectedTab = Keys.Metrics.obs;

  RxnString selectLastMonths = RxnString();
  List<String> lastMonthsSelectList = ['1', '2', '3', '4', '5'];

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void onTabChange(int index, String tab) {
    selectedTab.value = tab;
  }
}
