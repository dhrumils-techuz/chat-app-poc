import 'package:bluebird_p2_project/reporting/app/data/repository/spend_analysis_repository.dart';
import 'package:bluebird_p2_project/reporting/app/data/service/spend_analysis/spend_analysis_remote_service.dart';
import 'package:get/get.dart';

class SpendAnalysisController extends GetxController {
  final SpendAnalysisRepository spendAnalysisRepository;

  SpendAnalysisController({required this.spendAnalysisRepository});

  var lastMonthsSelectList =
      ['Last 3 Months', 'Last 6 Months', 'Last 9 Months', 'Last 12 Months'].obs;

  var selectLastMonths = 'Last 12 Months'.obs;

  var saleRepList = ['John Doe', 'Siddh', 'Ahmed', 'Sovran Prajapati'].obs;

  var selectSaleRep = 'John Doe'.obs;

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
}
