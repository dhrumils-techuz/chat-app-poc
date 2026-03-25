import 'package:get/get.dart';

import '../../../core/utils/dialog_helper.dart';
import '../../../core/values/app_strings.dart';
import '../../data/auth/jwt_auth_service.dart';
import '../../data/model/user_model.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/service/socket/socket_service.dart';
import '../../routes/app_pages.dart';

class ProfileController extends GetxController {
  final JwtAuthService _authService;
  final AuthRepository _authRepository;

  ProfileController({
    required JwtAuthService authService,
    required AuthRepository authRepository,
  })  : _authService = authService,
        _authRepository = authRepository;

  final isLoading = false.obs;
  final isLoggingOut = false.obs;

  UserModel? get currentUser => _authService.currentUser;

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

      try {
        Get.find<SocketService>().disconnect();
      } catch (_) {}

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
