import 'dart:io';

class ImageCompressionHelper {
  static const int defaultMaxWidth = 1920;
  static const int defaultMaxHeight = 1920;
  static const int thumbnailMaxWidth = 300;
  static const int thumbnailMaxHeight = 300;
  static const int defaultQuality = 80;
  static const int thumbnailQuality = 60;

  /// Checks if the image needs compression based on file size.
  static bool needsCompression(File file, {int? maxSizeBytes}) {
    final maxSize = maxSizeBytes ?? (2 * 1024 * 1024); // 2 MB default
    return file.lengthSync() > maxSize;
  }

  /// Calculates new dimensions while maintaining aspect ratio.
  static Size calculateResizedDimensions({
    required int originalWidth,
    required int originalHeight,
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
  }) {
    if (originalWidth <= maxWidth && originalHeight <= maxHeight) {
      return Size(originalWidth.toDouble(), originalHeight.toDouble());
    }

    double widthRatio = maxWidth / originalWidth;
    double heightRatio = maxHeight / originalHeight;
    double ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

    return Size(
      (originalWidth * ratio).roundToDouble(),
      (originalHeight * ratio).roundToDouble(),
    );
  }

  /// Generates a unique compressed file name.
  static String generateCompressedFileName(String originalPath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalPath.split('.').last.toLowerCase();
    return 'compressed_$timestamp.$extension';
  }

  /// Generates a unique thumbnail file name.
  static String generateThumbnailFileName(String originalPath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'thumb_$timestamp.jpg';
  }

  /// Gets the compression quality based on file size.
  static int getAdaptiveQuality(int fileSizeBytes) {
    if (fileSizeBytes < 1024 * 1024) return 90; // < 1MB
    if (fileSizeBytes < 3 * 1024 * 1024) return 80; // 1-3MB
    if (fileSizeBytes < 5 * 1024 * 1024) return 70; // 3-5MB
    return 60; // > 5MB
  }

  /// Validates image dimensions are within acceptable bounds.
  static bool isValidImageDimension(int width, int height) {
    return width > 0 &&
        height > 0 &&
        width <= 10000 &&
        height <= 10000;
  }

  /// Calculates the aspect ratio of an image.
  static double getAspectRatio(int width, int height) {
    if (height == 0) return 1.0;
    return width / height;
  }

  /// Determines the optimal display size for a chat bubble image.
  static Size getChatBubbleImageSize({
    required int originalWidth,
    required int originalHeight,
    double maxBubbleWidth = 250,
    double maxBubbleHeight = 350,
    double minBubbleWidth = 150,
    double minBubbleHeight = 100,
  }) {
    if (originalWidth == 0 || originalHeight == 0) {
      return Size(maxBubbleWidth, maxBubbleHeight * 0.6);
    }

    double aspectRatio = originalWidth / originalHeight;
    double width, height;

    if (aspectRatio > 1) {
      // Landscape
      width = maxBubbleWidth;
      height = width / aspectRatio;
      if (height < minBubbleHeight) {
        height = minBubbleHeight;
        width = height * aspectRatio;
      }
    } else {
      // Portrait or square
      height = maxBubbleHeight;
      width = height * aspectRatio;
      if (width < minBubbleWidth) {
        width = minBubbleWidth;
        height = width / aspectRatio;
      }
    }

    width = width.clamp(minBubbleWidth, maxBubbleWidth);
    height = height.clamp(minBubbleHeight, maxBubbleHeight);

    return Size(width, height);
  }
}

class Size {
  final double width;
  final double height;

  const Size(this.width, this.height);
}
