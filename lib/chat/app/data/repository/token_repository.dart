import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../core/utils/logs_helper.dart';
import '../../../core/values/constants/app_constants.dart';

/// Secure token repository using flutter_secure_storage for HIPAA compliance.
///
/// Stores JWT access and refresh tokens in platform-specific secure storage
/// (Keychain on iOS, Keystore on Android) instead of SharedPreferences.
class TokenRepository extends GetxService {
  static const String _tag = 'TokenRepository';

  static const String _keyAccessToken = 'chat_access_token';
  static const String _keyRefreshToken = 'chat_refresh_token';
  static const String _keyDeviceId = 'chat_device_id';
  static const String _keyTokenExpiryMs = 'chat_token_expiry_ms';

  final FlutterSecureStorage _secureStorage;

  /// In-memory cache for quick access without async reads.
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedDeviceId;
  DateTime? _tokenExpiryTime;

  TokenRepository({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Initializes the repository by loading cached values from secure storage.
  Future<TokenRepository> init() async {
    _cachedAccessToken = await _secureStorage.read(key: _keyAccessToken);
    _cachedRefreshToken = await _secureStorage.read(key: _keyRefreshToken);
    _cachedDeviceId = await _secureStorage.read(key: _keyDeviceId);

    final expiryStr = await _secureStorage.read(key: _keyTokenExpiryMs);
    if (expiryStr != null) {
      _tokenExpiryTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    }

    LogsHelper.debugLog(
        tag: _tag,
        'Token repository initialized. Has token: ${_cachedAccessToken != null}');
    return this;
  }

  // Access Token

  Future<void> saveAccessToken(String token) async {
    _cachedAccessToken = token;
    await _secureStorage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return _cachedAccessToken;
  }

  Future<void> deleteAccessToken() async {
    _cachedAccessToken = null;
    await _secureStorage.delete(key: _keyAccessToken);
  }

  // Refresh Token

  Future<void> saveRefreshToken(String token) async {
    _cachedRefreshToken = token;
    await _secureStorage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _cachedRefreshToken;
  }

  Future<void> deleteRefreshToken() async {
    _cachedRefreshToken = null;
    await _secureStorage.delete(key: _keyRefreshToken);
  }

  // Token Expiry

  void setTokenExpiry(int expiresInSeconds) {
    _tokenExpiryTime = DateTime.now().add(
      Duration(seconds: expiresInSeconds - AppConstants.tokenRefreshBufferSeconds),
    );
    _secureStorage.write(
      key: _keyTokenExpiryMs,
      value: _tokenExpiryTime!.millisecondsSinceEpoch.toString(),
    );
  }

  bool isAccessTokenExpired() {
    if (_tokenExpiryTime == null) return true;
    return DateTime.now().isAfter(_tokenExpiryTime!);
  }

  // Device ID

  Future<void> saveDeviceId(String deviceId) async {
    _cachedDeviceId = deviceId;
    await _secureStorage.write(key: _keyDeviceId, value: deviceId);
  }

  String? getDeviceId() {
    return _cachedDeviceId;
  }

  Future<void> deleteDeviceId() async {
    _cachedDeviceId = null;
    await _secureStorage.delete(key: _keyDeviceId);
  }

  // Session management

  bool get hasValidSession =>
      _cachedAccessToken != null && !isAccessTokenExpired();

  Future<void> clearAllTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedDeviceId = null;
    _tokenExpiryTime = null;

    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _keyDeviceId);
    await _secureStorage.delete(key: _keyTokenExpiryMs);

    LogsHelper.debugLog(tag: _tag, 'All tokens cleared');
  }
}
