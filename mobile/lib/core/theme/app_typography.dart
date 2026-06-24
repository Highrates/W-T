import 'package:flutter/material.dart';

import 'app_text_styles.dart';
import 'app_theme_colors.dart';

/// Material TextTheme, сопоставленный с Figma-стилями.
abstract final class AppTypography {
  static const String fontFamily = AppTextStyles.fontFamily;

  static TextTheme textTheme(AppThemeColors colors) => TextTheme(
        bodyMedium: AppTextStyles.textBody(color: colors.text),
        bodyLarge: AppTextStyles.text15_450(color: colors.text),
        bodySmall: AppTextStyles.text13_400(color: colors.caption),
        titleMedium: AppTextStyles.text14_550(color: colors.text),
        titleLarge: AppTextStyles.text18_600(color: colors.text),
        displayMedium: AppTextStyles.text18_600(color: colors.text),
      );
}
