import 'package:flutter/material.dart';

import 'app_theme_colors.dart';

/// Именованные текстовые стили (Figma).
abstract final class AppTextStyles {
  static const String fontFamily = 'Inter';

  static const double _letterSpacingBody = -0.4;
  static const double _letterSpacingTitle = -0.3;

  /// text-body: 14 / 400 / 18 / -0.4
  static TextStyle textBody({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 18 / 14,
        letterSpacing: _letterSpacingBody,
        fontVariations: const [FontVariation('wght', 400)],
        color: color,
      );

  /// text-15-450: 15 / 450 / 20 / -0.4
  static TextStyle text15_450({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        height: 20 / 15,
        letterSpacing: _letterSpacingBody,
        fontVariations: const [FontVariation('wght', 450)],
        color: color,
      );

  /// text-13-400: 13 / 400 / 16 / -0.4
  static TextStyle text13_400({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        height: 16 / 13,
        letterSpacing: _letterSpacingBody,
        fontVariations: const [FontVariation('wght', 400)],
        color: color,
      );

  /// text-14-550: 14 / 550 / 18 / -0.4
  static TextStyle text14_550({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 18 / 14,
        letterSpacing: _letterSpacingBody,
        fontVariations: const [FontVariation('wght', 550)],
        color: color,
      );

  /// text-18-600: 18 / 600 / 22 / -0.3
  static TextStyle text18_600({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        height: 22 / 18,
        letterSpacing: _letterSpacingTitle,
        fontVariations: const [FontVariation('wght', 600)],
        color: color,
      );
}

extension AppTextStylesContext on BuildContext {
  AppThemeColors get _colors => Theme.of(this).extension<AppThemeColors>()!;

  TextStyle get textBody => AppTextStyles.textBody(color: _colors.text);
  TextStyle get text15_450 => AppTextStyles.text15_450(color: _colors.text);
  TextStyle get text13_400 => AppTextStyles.text13_400(color: _colors.caption);
  TextStyle get text14_550 => AppTextStyles.text14_550(color: _colors.text);
  TextStyle get text18_600 => AppTextStyles.text18_600(color: _colors.text);
}
