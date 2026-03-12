import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../values/app_sizes.dart';

class ScreenUtil {
  static const baseSmallTabletWidth = 700;
  static const baseMediumTabletWidth = 800;
  static const baseLargeTabletWidth = 1000;
  static dynamic isMobileDevice;

  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static bool isMobile(BuildContext context) {
    return context.isPhone;
  }

  static bool isMobileWidth(double width) {
    return width < 600;
  }

  static bool isSmallTabletWidth(double width) {
    return width >= 600 && width < 720;
  }

  static bool isMediumTabletWidth(double width) {
    return width >= 720 && width < 900;
  }

  static bool isLargeTabletWidth(double width) {
    return width >= 900;
  }

  static double calculateAdaptiveWidth(double screenWidth, double width) {
    return isMobileWidth(screenWidth)
        ? ((screenWidth * width) / screenWidth)
        : isLargeTabletWidth(screenWidth)
            ? ((screenWidth * width) / baseLargeTabletWidth)
            : isMediumTabletWidth(screenWidth)
                ? ((screenWidth * width) / baseMediumTabletWidth)
                : ((screenWidth * width) / baseSmallTabletWidth);
  }

  static double getSplitScreenDetailRatio(BuildContext context) {
    return context.isPortrait ? 0.5 : 0.45;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static double getGridListItemWidth(bool showGrid, double screenWidth) {
    return showGrid
        ? ((screenWidth - (AppSizes.dimenToPx16 * 2) - AppSizes.dimenToPx20)) /
            2
        : 0;
  }
}
