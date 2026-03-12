import 'package:bluebird_p2_project/reporting/app/data/service/spend_analysis/spend_analysis_remote_service.dart';

import '../../client/dio_remote_api_client.dart';

class DioSpendAnalysisService implements SpendAnalysisRemoteService {
  DioRemoteApiClient dioRemoteApiClient;

  DioSpendAnalysisService({required this.dioRemoteApiClient});

  @override
  void getSpend() {
    // TODO: implement getSpend
  }
}
