import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart' show Get, GetNavigation;
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../../core/utils/logs_helper.dart';
import '../../../core/utils/shared_preference_helper.dart';
import '../../../core/values/constants/server_endpoints.dart';
import '../../routes/app_pages.dart';
import '../repository/token_repository.dart';

class DioRemoteApiClient extends GetxService {
  final Dio apiClient = Dio();
  final TokenRepository _tokenRepository;

  /// Completer used to queue concurrent requests while a token refresh is in progress.
  Completer<String?>? _refreshCompleter;

  DioRemoteApiClient(this._tokenRepository) {
    _initApiClient();
  }

  void _initApiClient() {
    apiClient.options.baseUrl = ApiEndpoints.baseURL;
    apiClient.options.connectTimeout = const Duration(seconds: 30);
    apiClient.options.receiveTimeout = const Duration(seconds: 30);
    apiClient.options.sendTimeout = const Duration(seconds: 30);

    final List<Interceptor> interceptors = <Interceptor>[];

    interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final excludedEndpoints = [
            '/auth/login',
            '/auth/register',
            '/auth/forgot-password',
            '/auth/reset-password',
          ];

          final isExcluded = excludedEndpoints
              .any((endpoint) => options.path.contains(endpoint));

          if (!isExcluded) {
            final token = await _getValidAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          final deviceId = _tokenRepository.getDeviceId();
          if (deviceId != null) {
            options.headers['X-Device-Id'] = deviceId;
          }
          options.headers['Content-Type'] = 'application/json';
          // Skip ngrok browser interstitial warning page (free tier)
          options.headers['ngrok-skip-browser-warning'] = 'true';

          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 &&
              !_isAuthEndpoint(error.requestOptions.path)) {
            try {
              final newToken = await _refreshAccessToken();
              if (newToken != null) {
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
                final retryResponse = await apiClient.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              }
              // newToken is null → refresh failed → session expired
              // _refreshAccessToken already called _handleSessionExpired()
            } catch (e) {
              LogsHelper.debugLog(
                  tag: 'DioClient', 'Token refresh failed during retry: $e');
            }
          }
          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
      ));
    }

    apiClient.interceptors.addAll(interceptors);
  }

  /// Parses expiresIn string like "15m", "1h", "30s" to seconds.
  static int _parseExpiresIn(dynamic value) {
    if (value is String) {
      final match = RegExp(r'^(\d+)([smhd]?)$').firstMatch(value.trim());
      if (match != null) {
        final num = int.parse(match.group(1)!);
        switch (match.group(2) ?? 's') {
          case 'm':
            return num * 60;
          case 'h':
            return num * 3600;
          case 'd':
            return num * 86400;
          default:
            return num;
        }
      }
    }
    return 900; // Default 15 minutes
  }

  /// Ensures the access token is valid (refreshes if expired).
  /// Used by SocketClient before connecting with the token.
  Future<void> ensureValidToken() async {
    await _getValidAccessToken();
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh');
  }

  /// Returns a valid access token. If the token is expired, refreshes it.
  /// Uses a queue pattern so only one refresh happens at a time.
  Future<String?> _getValidAccessToken() async {
    final token = await _tokenRepository.getAccessToken();
    if (token == null) return null;

    if (_tokenRepository.isAccessTokenExpired()) {
      return await _refreshAccessToken();
    }

    return token;
  }

  /// Whether a session expiry redirect is already in progress.
  bool _isRedirectingToLogin = false;

  /// Refreshes the access token using the refresh token.
  /// Queues concurrent callers so only one refresh request is made.
  /// If the refresh fails (expired/revoked refresh token), redirects to login.
  Future<String?> _refreshAccessToken() async {
    // If a refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _tokenRepository.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter!.complete(null);
        _handleSessionExpired();
        return null;
      }

      final response = await Dio().post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! <= 299) {
        final data = response.data['data'] as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;
        // expiresIn may be int (seconds) or string ("15m")
        final rawExpiresIn = data['expiresIn'];
        final expiresIn = rawExpiresIn is int
            ? rawExpiresIn
            : _parseExpiresIn(rawExpiresIn);

        await _tokenRepository.saveAccessToken(newAccessToken);
        await _tokenRepository.saveRefreshToken(newRefreshToken);
        _tokenRepository.setTokenExpiry(expiresIn);

        LogsHelper.debugLog(tag: 'DioClient', 'Token refreshed successfully');
        _refreshCompleter!.complete(newAccessToken);
        return newAccessToken;
      } else {
        LogsHelper.debugLog(
            tag: 'DioClient',
            'Token refresh returned status: ${response.statusCode}');
        _refreshCompleter!.complete(null);
        _handleSessionExpired();
        return null;
      }
    } catch (e) {
      LogsHelper.debugLog(tag: 'DioClient', 'Token refresh error: $e');
      _refreshCompleter!.complete(null);

      // If the refresh token request got a 401/403, the session is truly expired.
      // Redirect to login.
      if (e is DioException &&
          e.response?.statusCode != null &&
          (e.response!.statusCode == 401 || e.response!.statusCode == 403)) {
        _handleSessionExpired();
      }
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Clears all stored tokens/session data and redirects to the sign-in screen.
  /// Ensures only one redirect happens even if multiple requests fail concurrently.
  void _handleSessionExpired() {
    if (_isRedirectingToLogin) return;
    _isRedirectingToLogin = true;

    LogsHelper.debugLog(
        tag: 'DioClient', 'Session expired — redirecting to login');

    // Use post-frame callback to ensure we're not in the middle of a build.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _tokenRepository.clearAllTokens();
        SharedPreferenceHelper.clear();
        Get.offAllNamed(ChatAppRoutes.SIGN_IN);
      } catch (e) {
        LogsHelper.debugLog(
            tag: 'DioClient', 'Error during session expiry redirect: $e');
      } finally {
        _isRedirectingToLogin = false;
      }
    });
  }
}
