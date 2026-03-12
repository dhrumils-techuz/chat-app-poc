import 'dart:convert';

import 'package:bluebird_p2_project/reporting/core/data/api_response_model.dart';
import 'package:bluebird_p2_project/reporting/core/extenstion/dio_extensions.dart';

import '../../../../core/utils/date_time_helper.dart';
import '../../../../core/values/constants/api_fields.dart';
import '../../../../core/values/constants/server_endpoints.dart';
import '../../client/dio_remote_api_client.dart';
import 'auth_remote_service.dart';

class DioAuthService implements AuthRemoteService {
  DioRemoteApiClient dioRemoteApiClient;

  DioAuthService({required this.dioRemoteApiClient});

  @override
  Future<ApiResponseModel> login(bool confirmLogout,
      {int? deviceType, String? fcmToken}) async {
    var param = {
      ApiFields.confirmLogout: confirmLogout,
      ApiFields.Timezone: await DateTimeHelper.getDeviceTimezone(),
      ApiFields.DeviceType: deviceType,
      //ApiFields.NotificationId: fcmToken
    };
    return await dioRemoteApiClient.apiClient.safeApiCall(
        request: () => dioRemoteApiClient.apiClient
            .post(ApiEndpoints.login, data: json.encode(param)),
        useDefaultErrorHandler: true);
  }

  @override
  Future<ApiResponseModel> saveFcmToken(int deviceType, String fcmToken) async {
    var param = {
      ApiFields.DeviceType: deviceType,
      ApiFields.NotificationId: fcmToken
    };
    return await dioRemoteApiClient.apiClient.safeApiCall(
      request: () => dioRemoteApiClient.apiClient.post(
        ApiEndpoints.saveFCMToken,
        data: json.encode(param),
      ),
      useDefaultErrorHandler: false,
    );
  }

  @override
  Future<ApiResponseModel> logout() async {
    return await dioRemoteApiClient.apiClient.safeApiCall(
        request: () => dioRemoteApiClient.apiClient.post(ApiEndpoints.logout));
  }
}
