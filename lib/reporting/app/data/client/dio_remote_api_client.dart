import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../../core/values/constants/server_endpoints.dart';
import '../repository/token_repository.dart';

class DioRemoteApiClient extends GetxService {
  final Dio apiClient = Dio();
  final TokenRepository _tokenRepository;

  DioRemoteApiClient(this._tokenRepository) {
    initApiClient();
  }

  initApiClient() {
    apiClient.options.baseUrl = ApiEndpoints.baseURL;
    final List<Interceptor> interceptors = <Interceptor>[];
    interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Define endpoints that don't need the token
          final excludedEndpoints = [
            '/login', /* '/register'*/
          ];

          if (excludedEndpoints
              .any((endpoint) => options.path.contains(endpoint))) {
            final token = await _tokenRepository.getIdToken();
            final refreshToken = _tokenRepository.getRefreshToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              options.headers['RefreshToken'] = refreshToken;
              options.headers['Request-Type'] = 'login';
              options.headers['ngrok-skip-browser-warning'] = 'true';
              options.headers['app-source'] = 'bluebird';
            }
          } else {
            final token = await _tokenRepository.getIdToken();
            final refreshToken = _tokenRepository.getRefreshToken();
            final isNewIdToken = _tokenRepository.isNewIdToken;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              options.headers['RefreshToken'] = refreshToken;
              options.headers['New-Token'] = isNewIdToken;
              options.headers['ngrok-skip-browser-warning'] = 'true';
              options.headers['app-source'] = 'bluebird';
              options.headers['deviceid'] = _tokenRepository.getDeviceId();
            }
          }
          return handler.next(options); // Continue request
        },
        onResponse: (response, handler) {
          return handler.next(response); // Continue response
        },
        onError: (DioException error, handler) {
          return handler.next(error); // Continue error
        },
      ),
    );
    if (kDebugMode) {
      interceptors.add(PrettyDioLogger(
          requestHeader: true, requestBody: true, responseHeader: true));
    }
    apiClient.interceptors.addAll(interceptors);
  }
}
