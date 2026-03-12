import 'package:flutter/material.dart';

class AppColor {
  static const Color white = Colors.white;

  static const Color black = Colors.black;
  static const Color trBlack0x22000000 = Color(0x22000000);
  static const Color black0xFF222222 = Color(0xFF222222);

  static const Color blue0xFF6782E0 = Color(0xFF6782E0);
  static const Color blue0xFF686E93 = Color(0xFF686E93);

  static const Color grey0xFFEFEFEF = Color(0xFFEFEFEF);
  static const Color grey0xFFF2F5F8 = Color(0xFFF2F5F8);
  static const Color grey0xFFF7F8FA = Color(0xFFF7F8FA);
  static const Color grey0xFFF0F0F0 = Color(0xFFF0F0F0);
  static const Color grey0xFF707070 = Color(0xFF707070);

  static const Color green0xFFAFD79C = Color(0xFFAFD79C);

  static const Color red0xFFE43D3D = Color(0xFFE43D3D);
}

class AppColors extends ThemeExtension<AppColors> {
  static AppColors getInstance(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  final Color primaryColor;
  final Color onPrimaryColor;
  final Color colorOnBackground;
  final Color dividerColor;
  final Color bgImageColor;
  final Color errorColor;
  final Color surfaceColor;
  final Color backgroundColor;
  final Color colorOnSurface;
  final Color primaryContainer;
  final Color colorOnPrimary;
  final Color colorOnBackgroundSecondary;
  final Color selectItemColor;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color hintTextColor;
  final Color borderColor;

  //Snapshot colors

  //Call Analysis colors
  final Color unselectedTabColor;

  AppColors(
    this.primaryColor,
    this.onPrimaryColor,
    this.colorOnBackground,
    this.primaryContainer,
    this.dividerColor,
    this.bgImageColor,
    this.errorColor,
    this.surfaceColor,
    this.backgroundColor,
    this.colorOnSurface,
    this.colorOnPrimary,
    this.colorOnBackgroundSecondary,
    this.selectItemColor,
    this.secondaryContainer,
    this.onSecondaryContainer,
    this.hintTextColor,
    this.borderColor,
    //Snapshot colors

    //Call Analysis colors
    this.unselectedTabColor,
  );

  AppColors.light({
    this.primaryColor = AppColor.blue0xFF6782E0,
    this.primaryContainer = AppColor.blue0xFF6782E0,
    this.onPrimaryColor = AppColor.white,
    this.colorOnBackground = AppColor.black0xFF222222,
    this.dividerColor = AppColor.grey0xFFEFEFEF,
    this.bgImageColor = AppColor.green0xFFAFD79C,
    this.errorColor = AppColor.red0xFFE43D3D,
    this.surfaceColor = AppColor.white,
    this.backgroundColor = AppColor.grey0xFFF2F5F8,
    this.colorOnSurface = AppColor.black,
    this.colorOnPrimary = AppColor.white,
    this.colorOnBackgroundSecondary = AppColor.blue0xFF686E93,
    this.selectItemColor = AppColor.grey0xFFF7F8FA,
    this.secondaryContainer = AppColor.grey0xFFF7F8FA,
    this.onSecondaryContainer = AppColor.black,
    this.hintTextColor = AppColor.grey0xFFEFEFEF,
    this.borderColor = AppColor.grey0xFFF0F0F0,

    // Call Analysis colors
    this.unselectedTabColor = AppColor.grey0xFF707070,
  });

  @override
  ThemeExtension<AppColors> copyWith() {
    // TODO: implement copyWith
    throw UnimplementedError();
  }

  @override
  ThemeExtension<AppColors> lerp(
      covariant ThemeExtension<AppColors>? other, double t) {
    return AppColors(
      primaryColor,
      onPrimaryColor,
      colorOnBackground,
      primaryContainer,
      dividerColor,
      bgImageColor,
      errorColor,
      surfaceColor,
      backgroundColor,
      colorOnSurface,
      colorOnPrimary,
      colorOnBackgroundSecondary,
      selectItemColor,
      secondaryContainer,
      onSecondaryContainer,
      hintTextColor,
      borderColor,
      unselectedTabColor,
    );
  }
}
