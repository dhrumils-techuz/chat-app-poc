import 'package:bluebird_p2_project/reporting/app/data/service/auth/auth_remote_service.dart';

import '../../../core/data/api_response_model.dart';

class SignInRepository {
  final AuthRemoteService authService;

  SignInRepository({required this.authService});

  Future<ApiResponseModel> login(
    bool confirmLogout, {
    int? deviceType,
    String? fcmToken,
  }) {
    return authService.login(
      confirmLogout,
      deviceType: deviceType,
      fcmToken: fcmToken,
    );
  }
}
