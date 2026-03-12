import 'package:bluebird_p2_project/reporting/app/widgets/custom_divider.dart';
import 'package:bluebird_p2_project/reporting/app/widgets/drawer_list_item.dart';
import 'package:bluebird_p2_project/reporting/core/theme/text_style.dart';
import 'package:bluebird_p2_project/reporting/core/utils/screen_util.dart';
import 'package:bluebird_p2_project/reporting/core/values/app_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../core/theme/color.dart';
import '../../core/values/app_images.dart';
import '../../core/values/app_sizes.dart';
import '../modules/reporting_home/reporting_home_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer(
      {super.key,
      required this.routeItems,
      required this.selectIndex,
      required this.onItemTap});

  final List<AppRouteItem> routeItems;
  final int selectIndex;
  final void Function(int index) onItemTap;

  @override
  Widget build(BuildContext context) {
    AppColors myColors = AppColors.getInstance(context);
    return Container(
      color: myColors.onPrimaryColor,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: AppSizes.dimenToPx10,
            ),
            Row(
              children: [
                SizedBox(
                  width: AppSizes.dimenToPx20,
                ),
                ScreenUtil.isMobileDevice
                    ? GestureDetector(
                        onTap: () {
                          if (ScreenUtil.isMobile(context) &&
                              ScreenUtil.isPortrait(context)) {
                            Navigator.pop(context);
                          }
                        },
                        child: SvgPicture.asset(
                          AppImages.icCloseRoundLight,
                          height: AppSizes.dimenToPx24,
                          width: AppSizes.dimenToPx24,
                        ),
                      )
                    : SizedBox(
                        height: AppSizes.dimenToPx24,
                        width: AppSizes.dimenToPx24,
                      ),
                SizedBox(
                  width: AppSizes.dimenToPx10,
                ),
                Image.asset(
                  AppImages.blueBirdLogoIcon,
                  height: AppSizes.dimenToPx32,
                  width: AppSizes.dimenToPx32,
                ),
                SizedBox(
                  width: AppSizes.dimenToPx10,
                ),
                Text(
                  Keys.BlueBird.tr,
                  style: AppTextStyles.primaryTextRegularW400.copyWith(
                      fontSize: AppTextSizes.text26,
                      color: myColors.primaryColor),
                )
              ],
            ),
            SizedBox(
              height: AppSizes.dimenToPx25,
            ),
            ScreenUtil.isMobileDevice
                ? SizedBox()
                : CustomDivider(
                    height: AppSizes.dimenToPx1,
                  ),
            ScreenUtil.isMobileDevice
                ? SizedBox()
                : SizedBox(
                    height: AppSizes.dimenToPx20,
                  ),
            Expanded(
              child: ListView.builder(
                itemCount: routeItems.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                      onTap: () {
                        onItemTap.call(index);
                      },
                      child: ScreenUtil.isMobileDevice
                          ? DrawerListItem(
                              iconUrl: routeItems[index].iconUrl,
                              labelText: routeItems[index].label,
                              isSelect: index == selectIndex)
                          : Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: AppSizes.dimenToPx8,
                                  vertical: AppSizes.dimenToPx4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(AppSizes.dimenToPx8)),
                                color: index == selectIndex
                                    ? myColors.selectItemColor
                                    : myColors.onPrimaryColor,
                              ),
                              child: DrawerListItem(
                                  iconUrl: routeItems[index].iconUrl,
                                  labelText: routeItems[index].label,
                                  isSelect: index == selectIndex)));
                },
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: AppSizes.dimenToPx20,
                    ),
                    Container(
                      width: AppSizes.dimenToPx28,
                      height: AppSizes.dimenToPx28,
                      decoration: BoxDecoration(
                          color: myColors.bgImageColor, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          'JD',
                          style: AppTextStyles.primaryTextRegularW400.copyWith(
                              color: myColors.onPrimaryColor,
                              fontSize: AppTextSizes.text12),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: AppSizes.dimenToPx10,
                    ),
                    Text(
                      'John Doe',
                      style: AppTextStyles.primaryTextRegularW400.copyWith(
                          fontSize: AppTextSizes.text16,
                          color: myColors.colorOnBackground),
                    )
                  ],
                ),
                SizedBox(
                  height: AppSizes.dimenToPx10,
                ),
                CustomDivider(
                  height: AppSizes.dimenToPx1,
                  margin: EdgeInsets.only(
                      left: AppSizes.dimenToPx20, right: AppSizes.dimenToPx20),
                ),
                SizedBox(
                  height: AppSizes.dimenToPx10,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: AppSizes.dimenToPx20,
                    ),
                    SvgPicture.asset(
                      AppImages.icLogout,
                      height: AppSizes.dimenToPx28,
                      width: AppSizes.dimenToPx28,
                    ),
                    SizedBox(
                      width: AppSizes.dimenToPx10,
                    ),
                    Text(
                      Keys.Log_out.tr,
                      style: AppTextStyles.primaryTextRegularW400.copyWith(
                          fontSize: AppTextSizes.text16,
                          color: myColors.errorColor),
                    )
                  ],
                ),
                SizedBox(
                  height: AppSizes.dimenToPx10,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
