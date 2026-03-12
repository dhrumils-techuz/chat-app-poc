import 'dart:io';

import '../../../core/data/api_response_model.dart';
import '../service/media/media_remote_service.dart';

class MediaRepository {
  final MediaRemoteService _mediaService;

  MediaRepository({required MediaRemoteService mediaService})
      : _mediaService = mediaService;

  Future<ApiResponseModel> uploadMedia({
    required File file,
    required String fileName,
    required String mimeType,
    String? conversationId,
    Function(int, int)? onProgress,
  }) {
    return _mediaService.uploadMedia(
      file: file,
      fileName: fileName,
      mimeType: mimeType,
      conversationId: conversationId,
      onProgress: onProgress,
    );
  }

  Future<ApiResponseModel> uploadAvatar({
    required File file,
    required String fileName,
    Function(int, int)? onProgress,
  }) {
    return _mediaService.uploadAvatar(
      file: file,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  Future<ApiResponseModel> getPresignedUrl({
    required String fileName,
    required String mimeType,
  }) {
    return _mediaService.getPresignedUrl(
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<ApiResponseModel> deleteMedia(String mediaId) {
    return _mediaService.deleteMedia(mediaId);
  }
}
