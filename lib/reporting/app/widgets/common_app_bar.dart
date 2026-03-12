import 'package:bluebird_p2_project/reporting/core/theme/text_style.dart';
import 'package:bluebird_p2_project/reporting/core/values/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../core/theme/color.dart';
import '../../core/values/app_sizes.dart';

class CommonAppBar extends StatelessWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showSearch = false,
    this.showHamburgerMenuIcon = false,
    this.onMenuTap,
    this.onBackTap,
    this.onSearchTap,
  });

  final String title;
  final bool showBack;
  final bool showSearch;
  final bool showHamburgerMenuIcon;
  final Function()? onMenuTap;
  final Function()? onBackTap;
  final Function()? onSearchTap;

  @override
  Widget build(BuildContext context) {
    AppColors myColor = AppColors.getInstance(context);
    return Column(
      children: [
        SizedBox(
          height: AppSizes.dimenToPx16,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: AppSizes.dimenToPx18,
                ),
                if (showBack)
                  GestureDetector(
                    onTap: onBackTap,
                    child: SvgPicture.asset(
                      AppImages.icBack,
                      height: AppSizes.dimenToPx26,
                      width: AppSizes.dimenToPx26,
                    ),
                  ),
                if (showHamburgerMenuIcon)
                  GestureDetector(
                    onTap: onMenuTap ??
                        () {
                          Scaffold.of(context).openDrawer();
                        },
                    child: SvgPicture.asset(
                      AppImages.icMenu,
                      height: AppSizes.dimenToPx26,
                      width: AppSizes.dimenToPx26,
                    ),
                  ),
                if (showBack || showHamburgerMenuIcon)
                  SizedBox(
                    width: AppSizes.dimenToPx12,
                  ),
                Text(
                  title,
                  style: AppTextStyles.primaryTextSemiBoldW600.copyWith(
                    fontSize: AppTextSizes.text20,
                    color: myColor.onSecondaryContainer,
                  ),
                )
              ],
            ),
            showSearch
                ? Padding(
                    padding: EdgeInsets.only(right: AppSizes.dimenToPx18),
                    child: GestureDetector(
                      onTap: onSearchTap,
                      child: SvgPicture.asset(
                        AppImages.icSearchLight,
                        height: AppSizes.dimenToPx26,
                        width: AppSizes.dimenToPx26,
                      ),
                    ),
                  )
                : SizedBox(),
          ],
        ),
        SizedBox(
          height: AppSizes.dimenToPx16,
        ),
      ],
    );
  }
}
