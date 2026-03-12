import 'package:flutter/material.dart';

import 'color.dart';
import 'text_style.dart';

class ChatTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColor.primary,
      scaffoldBackgroundColor: AppColor.white,
      colorScheme: const ColorScheme.light(
        primary: AppColor.primary,
        secondary: AppColor.primaryLight,
        surface: AppColor.white,
        error: AppColor.error,
        onPrimary: AppColor.white,
        onSecondary: AppColor.white,
        onSurface: AppColor.black,
        onError: AppColor.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColor.white,
        foregroundColor: AppColor.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: ChatTextStyles.appBarTitle.copyWith(
          color: AppColor.black,
        ),
        iconTheme: const IconThemeData(color: AppColor.black),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColor.divider,
        thickness: 1,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        hintStyle: ChatTextStyles.body.copyWith(
          color: AppColor.grey5,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColor.primary,
        foregroundColor: AppColor.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColor.white,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: AppColor.grey5,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      extensions: const <ThemeExtension>[
        ChatColors.light(),
      ],
    );
  }
}
