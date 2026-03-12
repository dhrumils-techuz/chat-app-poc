import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/data/api_response_model.dart';
import '../../../../core/extension/dio_extensions.dart';
import '../../../../core/values/constants/server_endpoints.dart';
import '../../client/dio_remote_api_client.dart';
import 'media_remote_service.dart';

class DioMediaService implements MediaRemoteService {
  final DioRemoteApiClient _dioClient;

  DioMediaService({required DioRemoteApiClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<ApiResponseModel> uploadMedia({
    required File file,
    required String fileName,
    required String mimeType,
    String? conversationId,
    Function(int, int)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
      if (conversationId != null) 'conversationId': conversationId,
    });

    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.uploadMedia,
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      ),
    );
  }

  @override
  Future<ApiResponseModel> uploadAvatar({
    required File file,
    required String fileName,
    Function(int, int)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: DioMediaType.parse('image/jpeg'),
      ),
    });

    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.post(
        ApiEndpoints.uploadAvatar,
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      ),
    );
  }

  @override
  Future<ApiResponseModel> getPresignedUrl({
    required String fileName,
    required String mimeType,
  }) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.get(
        ApiEndpoints.getPresignedUrl,
        queryParameters: {
          'fileName': fileName,
          'mimeType': mimeType,
        },
      ),
    );
  }

  @override
  Future<ApiResponseModel> deleteMedia(String mediaId) async {
    return await _dioClient.apiClient.safeApiCall(
      request: () => _dioClient.apiClient.delete(
        ApiEndpoints.mediaById(mediaId),
      ),
    );
  }
}
