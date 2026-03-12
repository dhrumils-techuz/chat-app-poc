import 'package:bluebird_p2_project/reporting/core/theme/color.dart';
import 'package:bluebird_p2_project/reporting/core/theme/text_style.dart';
import 'package:bluebird_p2_project/reporting/core/utils/screen_util.dart';
import 'package:bluebird_p2_project/reporting/core/values/app_sizes.dart';
import 'package:flutter/material.dart';

class CommonTabWidget extends StatelessWidget {
  final List<String> tabNames;
  final List<Widget> tabChildren;
  final String selectedTab;
  final EdgeInsetsGeometry? padding;
  final Function(int index, String tab)? onTabChange;

  const CommonTabWidget({
    super.key,
    required this.selectedTab,
    required this.tabNames,
    required this.tabChildren,
    this.onTabChange,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.getInstance(context);
    final bool isMobile =
        ScreenUtil.isMobile(context) && ScreenUtil.isPortrait(context);

    return DefaultTabController(
      length: tabNames.length,
      child: Column(
        children: [
          TabBar(
            indicatorColor: colors.primaryColor,
            labelColor: colors.primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: AppSizes.dimenToPx2,
            dividerColor: colors.dividerColor,
            dividerHeight: AppSizes.dimenToPx1,
            isScrollable: !isMobile,
            padding: padding ??
                EdgeInsets.only(
                  left: isMobile ? AppSizes.dimenToPx16 : AppSizes.dimenToPx20,
                  right: isMobile ? AppSizes.dimenToPx16 : AppSizes.dimenToPx20,
                ),
            tabAlignment: isMobile ? null : TabAlignment.start,
            overlayColor: WidgetStateProperty.all(
              colors.primaryColor.withValues(alpha: 0.1),
            ),
            labelStyle: AppTextStyles.primaryTextRegularW400.copyWith(
              fontSize: AppTextSizes.text16,
            ),
            unselectedLabelStyle: AppTextStyles.primaryTextRegularW400.copyWith(
              fontSize: AppTextSizes.text16,
              color: AppColor.grey0xFF707070,
            ),
            onTap: (int index) {
              if (onTabChange != null) {
                if (index != tabNames.indexOf(selectedTab)) {
                  onTabChange?.call(index, tabNames[index]);
                }
              }
            },
            tabs: tabNames
                .map(
                  (String tabName) => Tab(
                    child: SizedBox(
                      width: isMobile ? null : AppSizes.dimenToPx140,
                      child: Center(child: Text(tabName)),
                    ),
                  ),
                )
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: tabChildren,
            ),
          ),
        ],
      ),
    );
  }
}
