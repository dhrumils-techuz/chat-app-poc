import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/theme/color.dart';
import '../../../core/theme/text_style.dart';
import '../../../core/values/app_sizes.dart';
import '../../widgets/gradient_button.dart';

class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final String url = args['url'] as String;
    final String name = args['name'] as String? ?? 'Document';
    final String? size = args['size'] as String?;
    final String? mimeType = args['mimeType'] as String?;

    final colors = ChatColors.getInstance(context);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Text(
          name,
          style: ChatTextStyles.appBarTitle.copyWith(
            color: colors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: colors.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.dimenToPx24),
          child: Card(
            color: colors.surfaceColor,
            elevation: 2,
            shadowColor: colors.shadowColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.dimenToPx16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.dimenToPx32,
                vertical: AppSizes.dimenToPx40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getFileIcon(mimeType),
                    size: AppSizes.dimenToPx80,
                    color: _getFileIconColor(mimeType, colors),
                  ),
                  const SizedBox(height: AppSizes.dimenToPx20),
                  Text(
                    name,
                    style: ChatTextStyles.heading.copyWith(
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (size != null) ...[
                    const SizedBox(height: AppSizes.dimenToPx8),
                    Text(
                      _formatFileSize(size),
                      style: ChatTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (mimeType != null) ...[
                    const SizedBox(height: AppSizes.dimenToPx4),
                    Text(
                      mimeType,
                      style: ChatTextStyles.caption.copyWith(
                        color: colors.textLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.dimenToPx32),
                  GradientButton(
                    text: 'Download & Open',
                    onTap: () => _launchDocument(url),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file_rounded;

    if (mimeType.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (mimeType.contains('word') || mimeType.contains('doc')) {
      return Icons.description_rounded;
    }
    if (mimeType.contains('sheet') ||
        mimeType.contains('excel') ||
        mimeType.contains('xls')) {
      return Icons.table_chart_rounded;
    }
    if (mimeType.contains('presentation') || mimeType.contains('ppt')) {
      return Icons.slideshow_rounded;
    }
    if (mimeType.contains('text')) return Icons.article_rounded;
    if (mimeType.contains('zip') || mimeType.contains('archive')) {
      return Icons.folder_zip_rounded;
    }
    if (mimeType.contains('image')) return Icons.image_rounded;
    if (mimeType.contains('audio')) return Icons.audio_file_rounded;
    if (mimeType.contains('video')) return Icons.video_file_rounded;

    return Icons.insert_drive_file_rounded;
  }

  Color _getFileIconColor(String? mimeType, ChatColors colors) {
    if (mimeType == null) return colors.iconColor;

    if (mimeType.contains('pdf')) return const Color(0xFFE53935);
    if (mimeType.contains('word') || mimeType.contains('doc')) {
      return const Color(0xFF1976D2);
    }
    if (mimeType.contains('sheet') ||
        mimeType.contains('excel') ||
        mimeType.contains('xls')) {
      return const Color(0xFF2E7D32);
    }
    if (mimeType.contains('presentation') || mimeType.contains('ppt')) {
      return const Color(0xFFE65100);
    }

    return colors.primaryColor;
  }

  String _formatFileSize(String size) {
    final bytes = int.tryParse(size);
    if (bytes == null) return size;

    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _launchDocument(String url) async {
    final result = await OpenFilex.open(url);
    if (result.type != ResultType.done) {
      Get.snackbar(
        'Error',
        'Could not open document: ${result.message}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
