import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../../core/utils/logs_helper.dart';
import '../../../core/values/constants/server_endpoints.dart';
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

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh-token');
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

  /// Refreshes the access token using the refresh token.
  /// Queues concurrent callers so only one refresh request is made.
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
        return null;
      }

      final response = await Dio().post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
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

        _refreshCompleter!.complete(newAccessToken);
        return newAccessToken;
      } else {
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      LogsHelper.debugLog(tag: 'DioClient', 'Token refresh error: $e');
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }
}
