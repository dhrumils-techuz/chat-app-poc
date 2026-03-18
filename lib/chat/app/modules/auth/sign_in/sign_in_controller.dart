import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/values/app_strings.dart';
import '../../../data/auth/jwt_auth_service.dart';
import '../../../data/model/login_response_model.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../data/repository/token_repository.dart';
import '../../../routes/app_pages.dart';

class SignInController extends GetxController {
  final AuthRepository _authRepository;
  final JwtAuthService _authService;

  SignInController({
    required AuthRepository authRepository,
    required TokenRepository tokenRepository,
    required JwtAuthService authService,
  })  : _authRepository = authRepository,
        _authService = authService;

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
        // Guard: if response is not a Map (e.g., HTML from captive portal),
        // treat as failure.
        if (response.data is! Map<String, dynamic>) {
          _handleLoginFailure('Unable to connect to server. Please check your network connection.');
          return;
        }
        // response.data is the full response body: { success, data: { tokens, user } }
        // Extract the 'data' field if it exists, otherwise use the whole map.
        final rawData = response.data as Map<String, dynamic>;
        final loginMap = rawData.containsKey('data')
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
        final loginData = LoginResponseData.fromJson(loginMap);

        // Store tokens and user session via JwtAuthService.
        // This sets currentUser, currentUserId, and persists user info.
        await _authService.handleLoginSuccess(loginData);

        // Reset failed attempts on successful login.
        failedAttempts.value = 0;
        _lockoutUntil = null;

        Get.offAllNamed(ChatAppRoutes.CHAT_LIST);
      } else {
        _handleLoginFailure(response.message ?? response.error);
      }
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');
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

    // Show snackbar only if the overlay is available.
    // Use WidgetsBinding.addPostFrameCallback to ensure the widget tree is
    // fully built before attempting to show the snackbar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.overlayContext != null && !Get.isSnackbarOpen) {
          Get.snackbar(
            Keys.Login_Failed.tr,
            errorMessage.value ?? Keys.Invalid_credentials.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColor.error.withValues(alpha: 0.15),
            colorText: AppColor.error,
            duration: const Duration(seconds: 3),
          );
        }
      } catch (_) {
        // Overlay not yet available — error already shown via errorMessage
      }
    });
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
