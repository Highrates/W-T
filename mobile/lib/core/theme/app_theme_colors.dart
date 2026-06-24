import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Семантические цвета темы (light / dark).
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.text,
    required this.secondBackground,
    required this.feedBackground,
    required this.caption,
    required this.accent,
    required this.blue,
    required this.green,
    required this.heroBackdrop,
    required this.onImagePrimary,
  });

  final Color background;
  final Color text;
  final Color secondBackground;
  final Color feedBackground;
  final Color caption;
  final Color accent;
  final Color blue;
  final Color green;
  final Color heroBackdrop;
  final Color onImagePrimary;

  /// Обводка карточек и полей: 12% `text`.
  Color get borderSubtle => text.withValues(alpha: 0.12);

  /// Лёгкая тень карточек: 4% `text`.
  Color get shadowSubtle => text.withValues(alpha: 0.04);

  static const AppThemeColors light = AppThemeColors(
    background: AppPalette.lightBackground,
    text: AppPalette.lightText,
    secondBackground: AppPalette.lightSecondBackground,
    feedBackground: AppPalette.lightSecondBackground,
    caption: AppPalette.lightCaption,
    accent: AppPalette.lightAccent,
    blue: AppPalette.blue,
    green: AppPalette.green,
    heroBackdrop: AppPalette.heroBackdrop,
    onImagePrimary: AppPalette.onImagePrimary,
  );

  static const AppThemeColors dark = AppThemeColors(
    background: AppPalette.darkBackground,
    text: AppPalette.darkText,
    secondBackground: AppPalette.darkSecondBackground,
    feedBackground: AppPalette.darkFeedBackground,
    caption: AppPalette.darkCaption,
    accent: AppPalette.darkAccent,
    blue: AppPalette.blue,
    green: AppPalette.green,
    heroBackdrop: AppPalette.heroBackdrop,
    onImagePrimary: AppPalette.onImagePrimary,
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? text,
    Color? secondBackground,
    Color? feedBackground,
    Color? caption,
    Color? accent,
    Color? blue,
    Color? green,
    Color? heroBackdrop,
    Color? onImagePrimary,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      text: text ?? this.text,
      secondBackground: secondBackground ?? this.secondBackground,
      feedBackground: feedBackground ?? this.feedBackground,
      caption: caption ?? this.caption,
      accent: accent ?? this.accent,
      blue: blue ?? this.blue,
      green: green ?? this.green,
      heroBackdrop: heroBackdrop ?? this.heroBackdrop,
      onImagePrimary: onImagePrimary ?? this.onImagePrimary,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      text: Color.lerp(text, other.text, t)!,
      secondBackground:
          Color.lerp(secondBackground, other.secondBackground, t)!,
      feedBackground: Color.lerp(feedBackground, other.feedBackground, t)!,
      caption: Color.lerp(caption, other.caption, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      green: Color.lerp(green, other.green, t)!,
      heroBackdrop: Color.lerp(heroBackdrop, other.heroBackdrop, t)!,
      onImagePrimary: Color.lerp(onImagePrimary, other.onImagePrimary, t)!,
    );
  }
}

extension AppThemeColorsContext on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
}
