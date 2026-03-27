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

  /// Shared overlay color resolver for all interactive widgets.
  /// Maps widget states (pressed, hovered, focused) to primary-tinted overlays.
  static WidgetStateProperty<Color?> _overlayColor(
      double pressedAlpha, double hoverAlpha) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColor.primary.withValues(alpha: pressedAlpha);
      }
      if (states.contains(WidgetState.hovered)) {
        return AppColor.primary.withValues(alpha: hoverAlpha);
      }
      if (states.contains(WidgetState.focused)) {
        return AppColor.primary.withValues(alpha: hoverAlpha);
      }
      return null;
    });
  }

  /// Builds the light [ThemeData] with [ChatColors.light] extension.
  static ThemeData get lightTheme {
    final overlay = _overlayColor(0.12, 0.06);
    // ButtonStyle applied to ALL icon buttons — including those inside AppBar.
    final iconStyle = ButtonStyle(overlayColor: overlay);

    return ThemeData(
      brightness: Brightness.light,
      // ColorScheme ensures M3 derives ALL overlays from primary.
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColor.primary,
        brightness: Brightness.light,
      ),
      splashColor: AppColor.primary.withValues(alpha: 0.12),
      highlightColor: AppColor.primary.withValues(alpha: 0.08),
      scaffoldBackgroundColor: AppColor.backgroundGrey,
      cardColor: AppColor.white,
      dividerColor: AppColor.divider,
      // AppBar icons get their own IconButtonTheme in M3 — override it.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColor.black),
        actionsIconTheme: IconThemeData(color: AppColor.black),
      ),
      // Global icon button style — covers non-AppBar icons.
      iconButtonTheme: IconButtonThemeData(style: iconStyle),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(overlayColor: overlay),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(overlayColor: overlay),
      ),
      extensions: const [ChatColors.light()],
    );
  }

  /// Builds the dark [ThemeData] with [ChatColors.dark] extension.
  static ThemeData get darkTheme {
    const darkColors = ChatColors.dark();
    final overlay = _overlayColor(0.18, 0.10);
    final iconStyle = ButtonStyle(overlayColor: overlay);

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColor.primary,
        brightness: Brightness.dark,
      ),
      splashColor: AppColor.primary.withValues(alpha: 0.15),
      highlightColor: AppColor.primary.withValues(alpha: 0.10),
      scaffoldBackgroundColor: darkColors.backgroundColor,
      cardColor: darkColors.surfaceColor,
      dividerColor: darkColors.dividerColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
        actionsIconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
      ),
      iconButtonTheme: IconButtonThemeData(style: iconStyle),
      popupMenuTheme: PopupMenuThemeData(
        color: darkColors.surfaceColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(overlayColor: overlay),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(overlayColor: overlay),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkColors.surfaceColor,
      ),
      extensions: const [ChatColors.dark()],
    );
  }
}
