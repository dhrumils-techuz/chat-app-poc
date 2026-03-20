import 'package:flutter/material.dart';

class AppColor {
  static const Color white = Colors.white;
  static const Color black = Color(0xFF09101D);
  static const Color primary = Color(0xFF10C17D);
  static const Color primaryLight = Color(0xFF01F094);
  static const Color primary10 = Color(0x1A10C17D);
  static const Color grey3 = Color(0xFF545D69);
  static const Color grey4 = Color(0xFF6D7580);
  static const Color grey5 = Color(0xFF858C94);
  static const Color divider = Color(0xFFDADEE3);
  static const Color shadow = Color(0x145A6CEA);
  static const Color sentBubble = Color(0xFFE7FFED);
  static const Color receivedBubble = Color(0xFFF2F4F7);
  static const Color error = Color(0xFFE43D3D);
  static const Color warning = Color(0xFFFFA726);
  static const Color success = Color(0xFF10C17D);
  static const Color unreadBadge = Color(0xFF10C17D);
  static const Color onlineGreen = Color(0xFF4CAF50);
  static const Color backgroundGrey = Color(0xFFF7F8FA);
  static const Color inputBackground = Color(0xFFF2F4F7);
  static const Color transparent = Color(0x00000000);
  static const Color overlayBackground = Color(0xFF000000);
  static const Color overlayForeground = Color(0xFFFFFFFF);
  static const Color overlaySubtle = Color(0x8AFFFFFF);
  static const Color readReceipt = Color(0xFF4FC3F7);

  // ── Dark theme colors ────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFE4E6EB);
  static const Color darkTextSecondary = Color(0xFFB0B3B8);
  static const Color darkTextTimestamp = Color(0xFF8A8D91);
  static const Color darkTextLight = Color(0xFF6D7074);
  static const Color darkDivider = Color(0xFF3A3B3C);
  static const Color darkBackground = Color(0xFF18191A);
  static const Color darkSurface = Color(0xFF242526);
  static const Color darkSentBubble = Color(0xFF0D3B24);
  static const Color darkReceivedBubble = Color(0xFF303132);
  static const Color darkError = Color(0xFFFF6B6B);
  static const Color darkShadow = Color(0x40000000);
  static const Color darkInputBackground = Color(0xFF303132);
  static const Color darkIcon = Color(0xFFB0B3B8);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-0.7, -0.7),
    end: Alignment(0.7, 0.7),
    colors: [primary, primaryLight],
  );
}

class ChatColors extends ThemeExtension<ChatColors> {
  static ChatColors getInstance(BuildContext context) {
    return Theme.of(context).extension<ChatColors>()!;
  }

  final Color primaryColor;
  final Color primaryLightColor;
  final Color onPrimaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTimestamp;
  final Color textLight;
  final Color dividerColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color sentBubbleColor;
  final Color receivedBubbleColor;
  final Color errorColor;
  final Color shadowColor;
  final Color inputBackgroundColor;
  final Color unreadBadgeColor;
  final Color onlineIndicatorColor;
  final Color iconColor;
  final Color iconActiveColor;
  final Color readReceiptColor;

  const ChatColors({
    required this.primaryColor,
    required this.primaryLightColor,
    required this.onPrimaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTimestamp,
    required this.textLight,
    required this.dividerColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.sentBubbleColor,
    required this.receivedBubbleColor,
    required this.errorColor,
    required this.shadowColor,
    required this.inputBackgroundColor,
    required this.unreadBadgeColor,
    required this.onlineIndicatorColor,
    required this.iconColor,
    required this.iconActiveColor,
    required this.readReceiptColor,
  });

  const ChatColors.light({
    this.primaryColor = AppColor.primary,
    this.primaryLightColor = AppColor.primaryLight,
    this.onPrimaryColor = AppColor.white,
    this.textPrimary = AppColor.black,
    this.textSecondary = AppColor.grey3,
    this.textTimestamp = AppColor.grey4,
    this.textLight = AppColor.grey5,
    this.dividerColor = AppColor.divider,
    this.backgroundColor = AppColor.backgroundGrey,
    this.surfaceColor = AppColor.white,
    this.sentBubbleColor = AppColor.sentBubble,
    this.receivedBubbleColor = AppColor.receivedBubble,
    this.errorColor = AppColor.error,
    this.shadowColor = AppColor.shadow,
    this.inputBackgroundColor = AppColor.inputBackground,
    this.unreadBadgeColor = AppColor.unreadBadge,
    this.onlineIndicatorColor = AppColor.onlineGreen,
    this.iconColor = AppColor.grey5,
    this.iconActiveColor = AppColor.primary,
    this.readReceiptColor = AppColor.readReceipt,
  });

  const ChatColors.dark({
    this.primaryColor = AppColor.primary,
    this.primaryLightColor = AppColor.primaryLight,
    this.onPrimaryColor = AppColor.white,
    this.textPrimary = AppColor.darkTextPrimary,
    this.textSecondary = AppColor.darkTextSecondary,
    this.textTimestamp = AppColor.darkTextTimestamp,
    this.textLight = AppColor.darkTextLight,
    this.dividerColor = AppColor.darkDivider,
    this.backgroundColor = AppColor.darkBackground,
    this.surfaceColor = AppColor.darkSurface,
    this.sentBubbleColor = AppColor.darkSentBubble,
    this.receivedBubbleColor = AppColor.darkReceivedBubble,
    this.errorColor = AppColor.darkError,
    this.shadowColor = AppColor.darkShadow,
    this.inputBackgroundColor = AppColor.darkInputBackground,
    this.unreadBadgeColor = AppColor.primary,
    this.onlineIndicatorColor = AppColor.onlineGreen,
    this.iconColor = AppColor.darkIcon,
    this.iconActiveColor = AppColor.primary,
    this.readReceiptColor = AppColor.readReceipt,
  });

  @override
  ThemeExtension<ChatColors> copyWith({
    Color? primaryColor,
    Color? primaryLightColor,
    Color? onPrimaryColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTimestamp,
    Color? textLight,
    Color? dividerColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? sentBubbleColor,
    Color? receivedBubbleColor,
    Color? errorColor,
    Color? shadowColor,
    Color? inputBackgroundColor,
    Color? unreadBadgeColor,
    Color? onlineIndicatorColor,
    Color? iconColor,
    Color? iconActiveColor,
    Color? readReceiptColor,
  }) {
    return ChatColors(
      primaryColor: primaryColor ?? this.primaryColor,
      primaryLightColor: primaryLightColor ?? this.primaryLightColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTimestamp: textTimestamp ?? this.textTimestamp,
      textLight: textLight ?? this.textLight,
      dividerColor: dividerColor ?? this.dividerColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      sentBubbleColor: sentBubbleColor ?? this.sentBubbleColor,
      receivedBubbleColor: receivedBubbleColor ?? this.receivedBubbleColor,
      errorColor: errorColor ?? this.errorColor,
      shadowColor: shadowColor ?? this.shadowColor,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
      unreadBadgeColor: unreadBadgeColor ?? this.unreadBadgeColor,
      onlineIndicatorColor: onlineIndicatorColor ?? this.onlineIndicatorColor,
      iconColor: iconColor ?? this.iconColor,
      iconActiveColor: iconActiveColor ?? this.iconActiveColor,
      readReceiptColor: readReceiptColor ?? this.readReceiptColor,
    );
  }

  @override
  ThemeExtension<ChatColors> lerp(
    covariant ThemeExtension<ChatColors>? other,
    double t,
  ) {
    if (other is! ChatColors) return this;
    return ChatColors(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      primaryLightColor:
          Color.lerp(primaryLightColor, other.primaryLightColor, t)!,
      onPrimaryColor: Color.lerp(onPrimaryColor, other.onPrimaryColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTimestamp: Color.lerp(textTimestamp, other.textTimestamp, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      sentBubbleColor: Color.lerp(sentBubbleColor, other.sentBubbleColor, t)!,
      receivedBubbleColor:
          Color.lerp(receivedBubbleColor, other.receivedBubbleColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      inputBackgroundColor:
          Color.lerp(inputBackgroundColor, other.inputBackgroundColor, t)!,
      unreadBadgeColor:
          Color.lerp(unreadBadgeColor, other.unreadBadgeColor, t)!,
      onlineIndicatorColor:
          Color.lerp(onlineIndicatorColor, other.onlineIndicatorColor, t)!,
      iconColor: Color.lerp(iconColor, other.iconColor, t)!,
      iconActiveColor: Color.lerp(iconActiveColor, other.iconActiveColor, t)!,
      readReceiptColor:
          Color.lerp(readReceiptColor, other.readReceiptColor, t)!,
    );
  }
}
