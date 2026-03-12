import 'package:flutter/material.dart';

class AppTextStyles {
  static const String _fontFamilyNAME = 'Roboto';
  static const String _fontVariablePropertyWeight = 'wght';

  static TextStyle primaryTextThinW100 = const TextStyle(
    fontFamily: _fontFamilyNAME,
    fontVariations: [FontVariation(_fontVariablePropertyWeight, 100)],
  );

  static TextStyle primaryTextExtraLightW200 = const TextStyle(
    fontFamily: _fontFamilyNAME,
    fontVariations: [FontVariation(_fontVariablePropertyWeight, 200)],
  );

  static TextStyle primaryTextLightW300 = const TextStyle(
    fontFamily: _fontFamilyNAME,
    fontVariations: [FontVariation(_fontVariablePropertyWeight, 300)],
  );

  static TextStyle primaryTextRegularW400 = const TextStyle(
    fontFamily: _fontFamilyNAME,
    fontVariations: [FontVariation(_fontVariablePropertyWeight, 400)],
  );

  static TextStyle primaryTextMediumW500 = const TextStyle(
    fontFamily: _fontFamilyNAME,
    fontVariations: [FontVariation(_fontVariablePropertyWeight, 500)],
  );

  static TextStyle primaryTextSemiBoldW600 = const TextStyle(
    fontFamily: _fontFamilyNAME,
    fontVariations: [FontVariation(_fontVariablePropertyWeight, 600)],
  );

  static TextStyle primaryTextBoldW700 = const TextStyle(
    fontFamily: _fontFamilyNAME,
    fontVariations: [FontVariation(_fontVariablePropertyWeight, 700)],
  );

  static TextStyle primaryTextExtraBoldW800 = const TextStyle(
    fontFamily: _fontFamilyNAME,
    fontVariations: [FontVariation(_fontVariablePropertyWeight, 800)],
  );

  static TextStyle primaryTextBlackW900 = const TextStyle(
    fontFamily: _fontFamilyNAME,
    fontVariations: [FontVariation(_fontVariablePropertyWeight, 900)],
  );
}
