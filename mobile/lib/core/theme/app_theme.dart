import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_text_styles.dart';
import 'app_theme_colors.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_radius.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';
export 'app_theme_colors.dart';
export 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppThemeColors.light, Brightness.light);

  static ThemeData get dark => _build(AppThemeColors.dark, Brightness.dark);

  static ThemeData _build(AppThemeColors colors, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: colors.background,
      textTheme: AppTypography.textTheme(colors),
      extensions: [colors],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.text,
        onPrimary: colors.background,
        secondary: colors.accent,
        onSecondary: colors.background,
        error: colors.accent,
        onError: colors.background,
        surface: colors.background,
        onSurface: colors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
          statusBarIconBrightness:
              isLight ? Brightness.dark : Brightness.light,
        ),
      ),
      dividerColor: colors.secondBackground,
    );
  }
}
