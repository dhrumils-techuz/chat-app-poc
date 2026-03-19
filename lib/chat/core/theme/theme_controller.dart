import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/shared_preference_helper.dart';
import 'color.dart';

/// Manages the app-wide theme mode (light, dark, system).
///
/// Persists the user's choice in SharedPreferences and provides reactive
/// [ThemeData] objects that include the [ChatColors] extension.
class ThemeController extends GetxController {
  /// The current theme mode: 'light', 'dark', or 'system'.
  final themeMode = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    final saved =
        SharedPreferenceHelper.getString(PreferenceKeys.themeMode) ?? 'system';
    themeMode.value = saved;
  }

  /// Sets the theme mode and persists it.
  void setThemeMode(String mode) {
    themeMode.value = mode;
    SharedPreferenceHelper.setString(PreferenceKeys.themeMode, mode);
    Get.changeThemeMode(_resolveThemeMode(mode));
  }

  /// Resolves a string to a Flutter [ThemeMode].
  ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Returns the initial [ThemeMode] from persisted preference.
  ThemeMode get initialThemeMode => _resolveThemeMode(themeMode.value);

  /// Builds the light [ThemeData] with [ChatColors.light] extension.
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: MaterialColor(AppColor.primary.value, const {
        50: Color(0xFFE8F8F0),
        100: Color(0xFFC6EDDA),
        200: Color(0xFFA0E1C1),
        300: Color(0xFF7AD5A8),
        400: Color(0xFF5ECB95),
        500: AppColor.primary,
        600: Color(0xFF0EB075),
        700: Color(0xFF0C9B6A),
        800: Color(0xFF0A875F),
        900: Color(0xFF066547),
      }),
      scaffoldBackgroundColor: AppColor.backgroundGrey,
      cardColor: AppColor.white,
      dividerColor: AppColor.divider,
      extensions: const [ChatColors.light()],
    );
  }

  /// Builds the dark [ThemeData] with [ChatColors.dark] extension.
  static ThemeData get darkTheme {
    const darkColors = ChatColors.dark();
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: MaterialColor(AppColor.primary.value, const {
        50: Color(0xFFE8F8F0),
        100: Color(0xFFC6EDDA),
        200: Color(0xFFA0E1C1),
        300: Color(0xFF7AD5A8),
        400: Color(0xFF5ECB95),
        500: AppColor.primary,
        600: Color(0xFF0EB075),
        700: Color(0xFF0C9B6A),
        800: Color(0xFF0A875F),
        900: Color(0xFF066547),
      }),
      scaffoldBackgroundColor: darkColors.backgroundColor,
      cardColor: darkColors.surfaceColor,
      dividerColor: darkColors.dividerColor,
      dialogTheme: DialogThemeData(
        backgroundColor: darkColors.surfaceColor,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkColors.surfaceColor,
      ),
      extensions: const [ChatColors.dark()],
    );
  }
}
