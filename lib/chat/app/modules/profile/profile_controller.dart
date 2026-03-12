import 'package:get/get.dart';

import '../../data/auth/jwt_auth_service.dart';
import '../../data/model/user_model.dart';

class ProfileController extends GetxController {
  final JwtAuthService _authService;

  ProfileController({required JwtAuthService authService})
      : _authService = authService;

  final isLoading = false.obs;

  UserModel? get currentUser => _authService.currentUser;

  @override
  void onInit() {
    super.onInit();
  }
}
