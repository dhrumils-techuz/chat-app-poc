import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/color.dart';
import '../../core/theme/text_style.dart';
import '../../core/values/app_images.dart';
import '../../core/values/app_sizes.dart';

class CommonCustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final String hint;
  final double borderWidth;
  final double borderRadius;
  final String iconPath;
  final double iconSize;
  final double width;
  final String Function(T) itemLabel;

  const CommonCustomDropdown({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.hint,
    required this.itemLabel,
    this.borderWidth = AppSizes.dimenToPx1,
    this.borderRadius = AppSizes.dimenToPx14,
    this.iconPath = AppImages.icDownArrow,
    this.iconSize = AppSizes.dimenToPx26,
    this.width = AppSizes.dimenToPx162, // Default width
  });

  @override
  Widget build(BuildContext context) {
    AppColors colors = AppColors.getInstance(context);
    return Container(
      height: AppSizes.dimenToPx50,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.dimenToPx14), // Inner padding
      decoration: BoxDecoration(
          border: Border.all(color: colors.borderColor),
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.white),
      // decoration: BoxDecoration(
      //   border: Border.all(color: colors.dropdownBorder, width: borderWidth),
      //   borderRadius: BorderRadius.circular(borderRadius),
      //   color: Colors.white,
      // ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: selectedValue,
          hint: Text(hint,
              style: AppTextStyles.primaryTextRegularW400.copyWith(
                color: colors.hintTextColor,
                fontSize: AppSizes.dimenToPx16,
              )),
          isExpanded: true,
          icon: SvgPicture.asset(
            iconPath,
            height: iconSize,
            width: iconSize,
          ),
          style: AppTextStyles.primaryTextRegularW400.copyWith(
            color: colors.colorOnSurface,
            fontSize: AppSizes.dimenToPx16,
          ),
          dropdownColor: colors.surfaceColor,
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                style: AppTextStyles.primaryTextRegularW400.copyWith(
                  color: colors.colorOnSurface,
                  fontSize: AppSizes.dimenToPx16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
