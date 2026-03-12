import 'package:flutter/material.dart';

import '../../core/theme/color.dart';
import '../../core/theme/text_style.dart';
import '../../core/values/app_sizes.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppSizes.avatarMedium,
    this.borderWidth = 0,
    this.borderColor,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.getInstance(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: borderWidth > 0
              ? Border.all(
                  color: borderColor ?? colors.primaryColor,
                  width: borderWidth,
                )
              : null,
        ),
        child: ClipOval(
          child: _buildContent(colors),
        ),
      ),
    );
  }

  Widget _buildContent(ChatColors colors) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitials(colors),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildInitials(colors);
        },
      );
    }
    return _buildInitials(colors);
  }

  Widget _buildInitials(ChatColors colors) {
    final initials = _getInitials();
    final bgColor = backgroundColor ?? _getColorFromName(colors);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: ChatTextStyles.semiBold.copyWith(
          fontSize: size * 0.38,
          color: textColor ?? colors.onPrimaryColor,
        ),
      ),
    );
  }

  String _getInitials() {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  Color _getColorFromName(ChatColors colors) {
    if (name == null || name!.isEmpty) return colors.primaryColor;
    final List<Color> avatarColors = [
      const Color(0xFF10C17D),
      const Color(0xFF5B8DEF),
      const Color(0xFFEF5B5B),
      const Color(0xFFFF9F43),
      const Color(0xFFA855F7),
      const Color(0xFF14B8A6),
      const Color(0xFFF43F5E),
      const Color(0xFF3B82F6),
    ];
    final index = name.hashCode.abs() % avatarColors.length;
    return avatarColors[index];
  }
}
