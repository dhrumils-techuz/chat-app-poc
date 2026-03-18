import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/color.dart';

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final imageUrl = args?['imageUrl'] as String? ?? '';
    final title = args?['title'] as String? ?? 'Image';

    return Scaffold(
      backgroundColor: AppColor.overlayBackground,
      appBar: AppBar(
        backgroundColor: AppColor.overlayBackground,
        foregroundColor: AppColor.overlayForeground,
        surfaceTintColor: Colors.transparent,
        title: Text(title),
        elevation: 0,
      ),
      body: Center(
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          backgroundDecoration: const BoxDecoration(color: AppColor.overlayBackground),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: AppColor.overlayForeground),
          ),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, color: AppColor.overlaySubtle, size: 64),
          ),
        ),
      ),
    );
  }
}
