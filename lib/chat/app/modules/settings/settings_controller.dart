import 'package:get/get.dart';

import '../../data/auth/jwt_auth_service.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/repository/token_repository.dart';
import '../../routes/app_pages.dart';

class SettingsController extends GetxController {
  final AuthRepository _authRepository;
  final TokenRepository _tokenRepository;
  final JwtAuthService _authService;

  SettingsController({
    required AuthRepository authRepository,
    required TokenRepository tokenRepository,
    required JwtAuthService authService,
  })  : _authRepository = authRepository,
        _tokenRepository = tokenRepository,
        _authService = authService;

  final isLoggingOut = false.obs;

  Future<void> logout() async {
    try {
      isLoggingOut.value = true;
      await _authRepository.logout();
    } catch (_) {
      // Best-effort logout on server
    } finally {
      await _authService.clearSession();
      isLoggingOut.value = false;
      Get.offAllNamed(ChatAppRoutes.SIGN_IN);
    }
  }
}
