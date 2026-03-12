import 'dart:convert';

import '../../../../core/data/api_response_model.dart';
import '../../../../core/extension/dio_extensions.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../../../core/values/constants/server_endpoints.dart';
import '../../client/dio_remote_api_client.dart';
import 'auth_remote_service.dart';

class DioAuthService implements AuthRemoteService {
  final DioRemoteApiClient _dioClient;

  DioAuthService({required DioRemoteApiClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<ApiResponseModel> login({
    required String email,
    required String password,
    int? deviceType,
    String? fcmToken,
  }) async {
    final params = {
      'email': email,
      'password': password,
      'timezone': await DateTimeHelper.getDeviceTimezone(),
      if (deviceType != null) 'deviceType': deviceType,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };

    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.login,
        data: json.encode(params),
      ),
      useDefaultErrorHandler: true,
    );
  }

  @override
  Future<ApiResponseModel> logout() async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(ApiEndpoints.logout),
      useDefaultErrorHandler: false,
    );
  }

  @override
  Future<ApiResponseModel> refreshToken({required String refreshToken}) async {
    final params = {
      'refreshToken': refreshToken,
    };

    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.refreshToken,
        data: json.encode(params),
      ),
      useDefaultErrorHandler: false,
    );
  }

  @override
  Future<ApiResponseModel> saveFcmToken({
    required int deviceType,
    required String fcmToken,
  }) async {
    final params = {
      'deviceType': deviceType,
      'fcmToken': fcmToken,
    };

    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.saveFcmToken,
        data: json.encode(params),
      ),
      useDefaultErrorHandler: false,
    );
  }
}
