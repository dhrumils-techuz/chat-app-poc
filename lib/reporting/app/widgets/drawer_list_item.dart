import 'package:bluebird_p2_project/reporting/core/theme/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

import '../../core/theme/text_style.dart';
import '../../core/utils/screen_util.dart';
import '../../core/values/app_images.dart';
import '../../core/values/app_sizes.dart';
import 'custom_divider.dart';

class DrawerListItem extends StatelessWidget {
  const DrawerListItem(
      {super.key,
      required this.iconUrl,
      required this.labelText,
      required this.isSelect});

  final String iconUrl;
  final String labelText;
  final bool isSelect;

  @override
  Widget build(BuildContext context) {
    AppColors myColors = AppColors.getInstance(context);
    return Column(
      children: [
        SizedBox(
          height: AppSizes.dimenToPx16,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                SizedBox(
                  width: AppSizes.dimenToPx20,
                ),
                SvgPicture.asset(
                  iconUrl,
                  width: AppSizes.dimenToPx22,
                  height: AppSizes.dimenToPx22,
                  colorFilter: ColorFilter.mode(
                      isSelect
                          ? myColors.primaryColor
                          : myColors.colorOnBackground,
                      BlendMode.srcIn),
                ),
                SizedBox(
                  width: AppSizes.dimenToPx10,
                ),
                Text(
                  labelText,
                  style: AppTextStyles.primaryTextRegularW400.copyWith(
                      fontSize: AppTextSizes.text16,
                      color: isSelect
                          ? myColors.primaryColor
                          : myColors.colorOnBackground),
                )
              ],
            ),
            Row(
              children: [
                SvgPicture.asset(
                  AppImages.icRightArrowLight,
                  width: AppSizes.dimenToPx24,
                  height: AppSizes.dimenToPx24,
                ),
                SizedBox(
                  width: AppSizes.dimenToPx20,
                ),
              ],
            ),
          ],
        ),
        SizedBox(
          height: AppSizes.dimenToPx16,
        ),
        ScreenUtil.isMobileDevice
            ? CustomDivider(
                margin: EdgeInsets.only(
                    left: AppSizes.dimenToPx20, right: AppSizes.dimenToPx20),
                height: AppSizes.dimenToPx1,
              )
            : SizedBox()
      ],
    );
  }
}
