import 'package:get/get.dart';

import '../../../core/utils/logs_helper.dart';
import '../../../core/utils/shared_preference_helper.dart';
import '../model/login_response_model.dart';
import '../model/user_model.dart';
import '../repository/token_repository.dart';

/// JWT authentication service for managing login state and user session.
///
/// Replaces the MS Azure AD auth from the reporting app.
/// Handles login response processing, session persistence,
/// and session cleanup on logout.
class JwtAuthService extends GetxService {
  static const String _tag = 'JwtAuthService';

  final TokenRepository _tokenRepository;

  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxBool _isLoggedIn = false.obs;

  UserModel? get currentUser => _currentUser.value;
  bool get isLoggedIn => _isLoggedIn.value;
  String? get currentUserId => _currentUser.value?.id;

  JwtAuthService(this._tokenRepository);

  /// Processes the login response and persists the session.
  Future<void> handleLoginSuccess(LoginResponseData loginData) async {
    await _tokenRepository.saveAccessToken(loginData.accessToken);
    await _tokenRepository.saveRefreshToken(loginData.refreshToken);
    _tokenRepository.setTokenExpiry(loginData.expiresIn);

    if (loginData.deviceId != null) {
      await _tokenRepository.saveDeviceId(loginData.deviceId!);
    }

    if (loginData.encryptionKey != null) {
      await SharedPreferenceHelper.setString(
        PreferenceKeys.dbEncryptionKey,
        loginData.encryptionKey!,
      );
    }

    _currentUser.value = loginData.user;
    _isLoggedIn.value = true;

    await _persistUserInfo(loginData.user);

    LogsHelper.debugLog(
        tag: _tag, 'Login success for user: ${loginData.user.name}');
  }

  /// Restores user session from persisted storage.
  Future<bool> restoreSession() async {
    try {
      final accessToken = await _tokenRepository.getAccessToken();
      if (accessToken == null) {
        LogsHelper.debugLog(tag: _tag, 'No access token found, session not restored');
        return false;
      }

      final userId = SharedPreferenceHelper.getString(PreferenceKeys.userId);
      final userName =
          SharedPreferenceHelper.getString(PreferenceKeys.userName);
      final userEmail =
          SharedPreferenceHelper.getString(PreferenceKeys.userEmail);

      if (userId == null || userName == null || userEmail == null) {
        LogsHelper.debugLog(tag: _tag, 'Incomplete user data, session not restored');
        return false;
      }

      _currentUser.value = UserModel(
        id: userId,
        name: userName,
        email: userEmail,
        avatarUrl:
            SharedPreferenceHelper.getString(PreferenceKeys.userAvatarUrl),
      );
      _isLoggedIn.value = true;

      LogsHelper.debugLog(tag: _tag, 'Session restored for user: $userName');
      return true;
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Session restore error: $e');
      return false;
    }
  }

  /// Clears the user session and all persisted data.
  Future<void> clearSession() async {
    await _tokenRepository.clearAllTokens();
    await SharedPreferenceHelper.clear();
    _currentUser.value = null;
    _isLoggedIn.value = false;
    LogsHelper.debugLog(tag: _tag, 'Session cleared');
  }

  /// Updates the current user model.
  void updateCurrentUser(UserModel user) {
    _currentUser.value = user;
    _persistUserInfo(user);
  }

  Future<void> _persistUserInfo(UserModel user) async {
    await SharedPreferenceHelper.setString(PreferenceKeys.userId, user.id);
    await SharedPreferenceHelper.setString(PreferenceKeys.userName, user.name);
    await SharedPreferenceHelper.setString(
        PreferenceKeys.userEmail, user.email);
    if (user.avatarUrl != null) {
      await SharedPreferenceHelper.setString(
          PreferenceKeys.userAvatarUrl, user.avatarUrl!);
    }
  }
}
