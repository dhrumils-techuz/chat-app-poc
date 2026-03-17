import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_strings.dart';
import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';

enum AttachmentType {
  document,
  camera,
  gallery,
  audio,
  location,
  contact,
}

class AttachmentPickerWidget extends StatelessWidget {
  const AttachmentPickerWidget({
    super.key,
    required this.onAttachmentSelected,
  });

  final void Function(AttachmentType type) onAttachmentSelected;

  static void show(
    BuildContext context, {
    required void Function(AttachmentType type) onAttachmentSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.transparent,
      builder: (_) => AttachmentPickerWidget(
        onAttachmentSelected: (type) {
          Navigator.of(context).pop();
          onAttachmentSelected(type);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colors.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Grid of attachment options
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              _AttachmentOption(
                icon: Icons.insert_drive_file_outlined,
                label: Keys.Document.tr,
                color: const Color(0xFF5B5FC7),
                onTap: () => onAttachmentSelected(AttachmentType.document),
              ),
              _AttachmentOption(
                icon: Icons.camera_alt_outlined,
                label: Keys.Camera.tr,
                color: const Color(0xFFE43D3D),
                onTap: () => onAttachmentSelected(AttachmentType.camera),
              ),
              _AttachmentOption(
                icon: Icons.photo_outlined,
                label: Keys.Gallery.tr,
                color: const Color(0xFFA855F7),
                onTap: () => onAttachmentSelected(AttachmentType.gallery),
              ),
              _AttachmentOption(
                icon: Icons.headphones_outlined,
                label: Keys.Audio.tr,
                color: const Color(0xFFFF9F43),
                onTap: () => onAttachmentSelected(AttachmentType.audio),
              ),
              _AttachmentOption(
                icon: Icons.location_on_outlined,
                label: Keys.Location.tr,
                color: const Color(0xFF10C17D),
                onTap: () => onAttachmentSelected(AttachmentType.location),
              ),
              _AttachmentOption(
                icon: Icons.person_outline,
                label: Keys.Contact.tr,
                color: const Color(0xFF3B82F6),
                onTap: () => onAttachmentSelected(AttachmentType.contact),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: ChatTextStyles.caption.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
