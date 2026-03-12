import '../../../core/data/api_response_model.dart';
import '../service/auth/auth_remote_service.dart';

class AuthRepository {
  final AuthRemoteService _authService;

  AuthRepository({required AuthRemoteService authService})
      : _authService = authService;

  Future<ApiResponseModel> login({
    required String email,
    required String password,
    int? deviceType,
    String? fcmToken,
  }) {
    return _authService.login(
      email: email,
      password: password,
      deviceType: deviceType,
      fcmToken: fcmToken,
    );
  }

  Future<ApiResponseModel> logout() {
    return _authService.logout();
  }

  Future<ApiResponseModel> refreshToken({required String refreshToken}) {
    return _authService.refreshToken(refreshToken: refreshToken);
  }

  Future<ApiResponseModel> saveFcmToken({
    required int deviceType,
    required String fcmToken,
  }) {
    return _authService.saveFcmToken(
      deviceType: deviceType,
      fcmToken: fcmToken,
    );
  }
}
