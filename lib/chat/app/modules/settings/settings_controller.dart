import 'package:get/get.dart';

import '../../../core/utils/dialog_helper.dart';
import '../../../core/values/app_strings.dart';
import '../../data/auth/jwt_auth_service.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/repository/token_repository.dart';
import '../../data/service/socket/socket_service.dart';
import '../../routes/app_pages.dart';

class SettingsController extends GetxController {
  final AuthRepository _authRepository;
  final JwtAuthService _authService;

  SettingsController({
    required AuthRepository authRepository,
    required TokenRepository tokenRepository,
    required JwtAuthService authService,
  })  : _authRepository = authRepository,
        _authService = authService;

  final isLoggingOut = false.obs;

  void logout() {
    DialogHelper.showConfirmationDialog(
      Keys.Logout.tr,
      Keys.Logout_confirm.tr,
      btnPositiveText: Keys.Logout.tr,
      btnNegativeText: Keys.Cancel.tr,
      onPositiveResponse: _performLogout,
    );
  }

  Future<void> _performLogout() async {
    try {
      isLoggingOut.value = true;

      // Disconnect socket before clearing session
      try {
        Get.find<SocketService>().disconnect();
      } catch (_) {
        // SocketService might not be initialized
      }

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
