import '../../../../core/data/api_response_model.dart';

abstract class AuthRemoteService {
  Future<ApiResponseModel> login({
    required String email,
    required String password,
    int? deviceType,
    String? fcmToken,
  });

  Future<ApiResponseModel> logout();

  Future<ApiResponseModel> refreshToken({required String refreshToken});

  Future<ApiResponseModel> saveFcmToken({
    required int deviceType,
    required String fcmToken,
  });
}
