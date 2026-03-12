import 'dart:io';

import 'package:path/path.dart' as path;

import 'logs_helper.dart';

class FileHelper {
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxAudioSizeBytes = 15 * 1024 * 1024; // 15 MB

  static const List<String> allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic',
    '.heif',
  ];

  static const List<String> allowedDocumentExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
    '.csv',
  ];

  static const List<String> allowedAudioExtensions = [
    '.mp3',
    '.wav',
    '.aac',
    '.m4a',
    '.ogg',
    '.flac',
  ];

  /// Returns the file extension in lowercase.
  static String getExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  /// Returns the file name without extension.
  static String getFileName(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// Returns the full file name with extension.
  static String getFullFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Returns the MIME type based on file extension.
  static String? getMimeType(String filePath) {
    final ext = getExtension(filePath);
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      case '.m4a':
        return 'audio/mp4';
      case '.ogg':
        return 'audio/ogg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Checks if the file is an image based on extension.
  static bool isImage(String filePath) {
    return allowedImageExtensions.contains(getExtension(filePath));
  }

  /// Checks if the file is a document based on extension.
  static bool isDocument(String filePath) {
    return allowedDocumentExtensions.contains(getExtension(filePath));
  }

  /// Checks if the file is an audio file based on extension.
  static bool isAudio(String filePath) {
    return allowedAudioExtensions.contains(getExtension(filePath));
  }

  /// Validates file size against the maximum allowed size.
  static bool isFileSizeValid(File file, {int? maxSize}) {
    final size = file.lengthSync();
    return size <= (maxSize ?? maxFileSizeBytes);
  }

  /// Formats file size to human-readable string.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Generates a unique file name with timestamp.
  static String generateUniqueFileName(String originalName) {
    final ext = getExtension(originalName);
    final name = getFileName(originalName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${name}_$timestamp$ext';
  }

  /// Deletes a file safely without throwing errors.
  static Future<bool> deleteFileSafely(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      LogsHelper.debugLog('Failed to delete file: $e', tag: 'FileHelper');
      return false;
    }
  }
}
