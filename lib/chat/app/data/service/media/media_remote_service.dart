import 'dart:io';

import '../../../../core/data/api_response_model.dart';

abstract class MediaRemoteService {
  Future<ApiResponseModel> uploadMedia({
    required File file,
    required String fileName,
    required String mimeType,
    String? conversationId,
    Function(int, int)? onProgress,
  });

  Future<ApiResponseModel> uploadAvatar({
    required File file,
    required String fileName,
    Function(int, int)? onProgress,
  });

  Future<ApiResponseModel> getPresignedUrl({
    required String fileName,
    required String mimeType,
  });

  Future<ApiResponseModel> deleteMedia(String mediaId);
}
