import '../../../../core/data/api_response_model.dart';

abstract class AuthRemoteService {
  Future<ApiResponseModel> login(
    bool confirmLogout, {
    int? deviceType,
    String? fcmToken,
  });
  Future<ApiResponseModel> saveFcmToken(
    int deviceType,
    String fcmToken,
  );

  Future<ApiResponseModel> logout();
}
