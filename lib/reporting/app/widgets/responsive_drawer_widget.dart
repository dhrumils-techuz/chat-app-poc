import 'package:bluebird_p2_project/reporting/core/theme/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/values/app_sizes.dart';

class ResponsiveDrawerWidget extends StatelessWidget {
  const ResponsiveDrawerWidget({
    Key? key,
    // menu and content are now configurable
    required this.menu,
    required this.content,
    // these values are now configurable with sensible default values
    this.breakpoint = 600,
    this.menuWidth = 300,
  }) : super(key: key);

  final Widget menu;
  final Widget content;
  final double breakpoint;
  final double menuWidth;

  @override
  Widget build(BuildContext context) {
    AppColors myColors = AppColors.getInstance(context);
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= breakpoint) {
      // widescreen: menu on the left, content on the right
      return Scaffold(
        body: Container(
          color: myColors.onPrimaryColor,
          child: Row(
            children: [
              SizedBox(
                width: menuWidth,
                child: menu,
              ),
              Container(
                  width: AppSizes.dimenToPx1, color: myColors.dividerColor),
              Expanded(child: content),
            ],
          ),
        ),
      );
    } else {
      // narrow screen: show content, menu inside drawer
      return Scaffold(
        body: content,
        drawer: SizedBox(
          width: menuWidth,
          child: Container(
            color: Colors.white,
            child: Drawer(
              child: menu,
            ),
          ),
        ),
      );
    }
  }
}
