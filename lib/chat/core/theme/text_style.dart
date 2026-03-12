import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ChatTextStyles {
  static String get _fontFamily {
    if (kIsWeb) return 'Roboto';
    if (Platform.isIOS || Platform.isMacOS) return 'SourceSansPro';
    return 'Roboto';
  }

  static const String _fontVariablePropertyWeight = 'wght';

  // Weight variants
  static TextStyle get regular => TextStyle(
        fontFamily: _fontFamily,
        fontVariations: const [
          FontVariation(_fontVariablePropertyWeight, 400),
        ],
      );

  static TextStyle get semiBold => TextStyle(
        fontFamily: _fontFamily,
        fontVariations: const [
          FontVariation(_fontVariablePropertyWeight, 600),
        ],
      );

  // Predefined text styles matching Figma design tokens
  static TextStyle get title => semiBold.copyWith(fontSize: 26);

  static TextStyle get heading => semiBold.copyWith(fontSize: 18);

  static TextStyle get body => regular.copyWith(fontSize: 16);

  static TextStyle get bodySemiBold => semiBold.copyWith(fontSize: 16);

  static TextStyle get small => regular.copyWith(fontSize: 14);

  static TextStyle get smallSemiBold => semiBold.copyWith(fontSize: 14);

  static TextStyle get caption => regular.copyWith(fontSize: 11);

  static TextStyle get captionSemiBold => semiBold.copyWith(fontSize: 11);

  // Chat-specific text styles
  static TextStyle get conversationTitle => semiBold.copyWith(fontSize: 16);

  static TextStyle get conversationPreview => regular.copyWith(fontSize: 14);

  static TextStyle get messageBody => regular.copyWith(fontSize: 16);

  static TextStyle get messageTimestamp => regular.copyWith(fontSize: 11);

  static TextStyle get badgeCount => semiBold.copyWith(fontSize: 11);

  static TextStyle get inputText => regular.copyWith(fontSize: 16);

  static TextStyle get appBarTitle => semiBold.copyWith(fontSize: 18);

  static TextStyle get buttonText => semiBold.copyWith(fontSize: 16);
}
