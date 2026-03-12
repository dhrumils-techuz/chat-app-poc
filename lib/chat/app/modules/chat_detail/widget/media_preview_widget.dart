import 'package:flutter/material.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../data/model/media_attachment_model.dart';
import '../../../data/types/message_type.dart';
import '../../../routes/app_pages.dart';
import 'package:get/get.dart';

class MediaPreviewWidget extends StatelessWidget {
  const MediaPreviewWidget({
    super.key,
    required this.attachment,
    this.isMyMessage = true,
  });

  final MediaAttachmentModel attachment;
  final bool isMyMessage;

  @override
  Widget build(BuildContext context) {
    switch (attachment.mediaType) {
      case MessageType.image:
        return _ImagePreview(
          attachment: attachment,
          isMyMessage: isMyMessage,
        );
      case MessageType.audio:
        return _AudioPreview(
          attachment: attachment,
          isMyMessage: isMyMessage,
        );
      case MessageType.document:
      case MessageType.file:
        return _DocumentPreview(
          attachment: attachment,
          isMyMessage: isMyMessage,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Image Preview ──────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.attachment,
    required this.isMyMessage,
  });

  final MediaAttachmentModel attachment;
  final bool isMyMessage;

  @override
  Widget build(BuildContext context) {
    final imageUrl = attachment.thumbnailUrl ?? attachment.url;
    final maxWidth = AppSizes.bubbleMaxWidth - (AppSizes.bubblePadding * 2);

    double? displayWidth;
    double? displayHeight;
    if (attachment.width != null && attachment.height != null) {
      final aspectRatio = attachment.width! / attachment.height!;
      displayWidth = maxWidth;
      displayHeight = maxWidth / aspectRatio;
      if (displayHeight > 300) {
        displayHeight = 300;
        displayWidth = 300 * aspectRatio;
        if (displayWidth > maxWidth) displayWidth = maxWidth;
      }
    }

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          ChatAppRoutes.MEDIA_VIEWER,
          arguments: {'url': attachment.url, 'type': 'image'},
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: displayWidth ?? maxWidth,
          height: displayHeight ?? 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: displayWidth ?? maxWidth,
              height: displayHeight ?? 200,
              color: AppColor.inputBackground,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: displayWidth ?? maxWidth,
              height: displayHeight ?? 200,
              color: AppColor.inputBackground,
              child: const Center(
                child: Icon(Icons.broken_image_outlined, size: 40),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Audio Preview ──────────────────────────────────────────────────────────

class _AudioPreview extends StatefulWidget {
  const _AudioPreview({
    required this.attachment,
    required this.isMyMessage,
  });

  final MediaAttachmentModel attachment;
  final bool isMyMessage;

  @override
  State<_AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<_AudioPreview> {
  bool _isPlaying = false;
  double _progress = 0.0;

  String get _durationText {
    final seconds = widget.attachment.durationInSeconds ?? 0;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return SizedBox(
      width: AppSizes.bubbleMaxWidth - (AppSizes.bubblePadding * 2),
      child: Row(
        children: [
          // Play / Pause button
          GestureDetector(
            onTap: () {
              setState(() => _isPlaying = !_isPlaying);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColor.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColor.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Waveform + duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform bars
                SizedBox(
                  height: 24,
                  child: CustomPaint(
                    size: const Size(double.infinity, 24),
                    painter: _WaveformPainter(
                      progress: _progress,
                      activeColor: colors.primaryColor,
                      inactiveColor: widget.isMyMessage
                          ? colors.primaryColor.withOpacity(0.3)
                          : colors.iconColor.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _durationText,
                  style: ChatTextStyles.caption.copyWith(
                    color: colors.textTimestamp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  // Simulated waveform heights
  static const List<double> _bars = [
    0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.3, 0.7, 0.5, 0.9,
    0.4, 0.6, 0.8, 0.5, 0.7, 0.3, 0.9, 0.6, 0.5, 0.8,
    0.4, 0.7, 0.6, 0.9, 0.5, 0.7, 0.3, 0.8, 0.6, 0.4,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.0;
    final gap = (size.width - _bars.length * barWidth) / (_bars.length - 1);

    for (int i = 0; i < _bars.length; i++) {
      final x = i * (barWidth + gap);
      final barHeight = _bars[i] * size.height;
      final y = (size.height - barHeight) / 2;

      final isActive = (i / _bars.length) < progress;
      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ── Document Preview ───────────────────────────────────────────────────────

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({
    required this.attachment,
    required this.isMyMessage,
  });

  final MediaAttachmentModel attachment;
  final bool isMyMessage;

  IconData get _fileIcon {
    final mime = attachment.mimeType?.toLowerCase() ?? '';
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mime.contains('word') || mime.contains('doc')) {
      return Icons.description_outlined;
    }
    if (mime.contains('sheet') || mime.contains('excel') || mime.contains('xls')) {
      return Icons.table_chart_outlined;
    }
    if (mime.contains('presentation') || mime.contains('ppt')) {
      return Icons.slideshow_outlined;
    }
    if (mime.contains('zip') || mime.contains('rar') || mime.contains('tar')) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Color _fileIconColor(ChatColors colors) {
    final mime = attachment.mimeType?.toLowerCase() ?? '';
    if (mime.contains('pdf')) return const Color(0xFFE43D3D);
    if (mime.contains('word') || mime.contains('doc')) {
      return const Color(0xFF3B82F6);
    }
    if (mime.contains('sheet') || mime.contains('excel') || mime.contains('xls')) {
      return const Color(0xFF10C17D);
    }
    if (mime.contains('presentation') || mime.contains('ppt')) {
      return const Color(0xFFFF9F43);
    }
    return colors.iconColor;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Container(
      width: AppSizes.bubbleMaxWidth - (AppSizes.bubblePadding * 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMyMessage
            ? colors.primaryColor.withOpacity(0.08)
            : colors.inputBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _fileIconColor(colors).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _fileIcon,
              size: 22,
              color: _fileIconColor(colors),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.fileName,
                  style: ChatTextStyles.smallSemiBold.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  attachment.fileSizeFormatted,
                  style: ChatTextStyles.caption.copyWith(
                    color: colors.textTimestamp,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.download_outlined,
            size: 20,
            color: colors.iconColor,
          ),
        ],
      ),
    );
  }
}
