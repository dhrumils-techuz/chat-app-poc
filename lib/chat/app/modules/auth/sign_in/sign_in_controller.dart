import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/model/login_response_model.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../data/repository/token_repository.dart';
import '../../../routes/app_pages.dart';

class SignInController extends GetxController {
  final AuthRepository _authRepository;
  final TokenRepository _tokenRepository;

  SignInController({
    required AuthRepository authRepository,
    required TokenRepository tokenRepository,
  })  : _authRepository = authRepository,
        _tokenRepository = tokenRepository;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final errorMessage = RxnString();

  /// HIPAA: Track failed login attempts client-side.
  final failedAttempts = 0.obs;

  /// HIPAA: Lockout threshold before temporary client-side lockout.
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  DateTime? _lockoutUntil;

  /// Whether the account is currently locked out due to failed attempts.
  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      failedAttempts.value = 0;
      return false;
    }
    return true;
  }

  /// Returns the remaining lockout duration, or null if not locked out.
  Duration? get remainingLockoutDuration {
    if (_lockoutUntil == null) return null;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    if (remaining.isNegative) return null;
    return remaining;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login() async {
    errorMessage.value = null;

    if (isLockedOut) {
      final remaining = remainingLockoutDuration;
      if (remaining != null) {
        errorMessage.value =
            'Account temporarily locked. Try again in ${remaining.inMinutes + 1} minutes.';
      }
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;

    try {
      final response = await _authRepository.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.isSuccessful && response.data != null) {
        final loginData = LoginResponseData.fromJson(
          response.data as Map<String, dynamic>,
        );

        // Store tokens securely.
        await _tokenRepository.saveAccessToken(loginData.accessToken);
        await _tokenRepository.saveRefreshToken(loginData.refreshToken);
        _tokenRepository.setTokenExpiry(loginData.expiresIn);

        if (loginData.deviceId != null) {
          await _tokenRepository.saveDeviceId(loginData.deviceId!);
        }

        // Reset failed attempts on successful login.
        failedAttempts.value = 0;
        _lockoutUntil = null;

        Get.offAllNamed(ChatAppRoutes.CHAT_LIST);
      } else {
        _handleLoginFailure(response.message ?? response.error);
      }
    } catch (e) {
      _handleLoginFailure('An unexpected error occurred. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void _handleLoginFailure(String? message) {
    failedAttempts.value++;

    if (failedAttempts.value >= _maxFailedAttempts) {
      _lockoutUntil = DateTime.now().add(_lockoutDuration);
      errorMessage.value =
          'Too many failed attempts. Account locked for ${_lockoutDuration.inMinutes} minutes.';
    } else {
      final attemptsRemaining = _maxFailedAttempts - failedAttempts.value;
      errorMessage.value = message ?? 'Invalid credentials.';
      if (attemptsRemaining <= 2) {
        errorMessage.value =
            '${errorMessage.value} ($attemptsRemaining attempts remaining)';
      }
    }

    Get.snackbar(
      'Login Failed',
      errorMessage.value ?? 'Invalid credentials.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
