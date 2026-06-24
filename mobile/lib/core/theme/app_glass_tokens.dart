import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Общие параметры glass (nav + чипы).
abstract final class AppGlassTokens {
  /// Fill #F7F7F7 @ 80% — чипы шапки (light).
  static const Color lightFill = Color(0xCCF7F7F7);

  /// Fill black @ 40% — [AppBottomNavBar].
  static const Color navBarFill = Color(0x66000000);

  /// Иконки nav: white @ 80%.
  static const Color navInactiveIcon = Color(0xCCFFFFFF);

  /// Обводка круглых кнопок nav (бургер, профиль) — glass rim.
  static const double navCircleBorderWidth = 1;
  static final Color navCircleBorderColor =
      navInactiveIcon.withValues(alpha: 0.4);

  /// Активный пункт trio: white @ 80%.
  static const Color navActiveIndicator = Color(0xCCFFFFFF);

  static const Color navActiveIcon = Color(0xFF000000);

  /// Текст и иконки в [GlassChipButton] (тот же glass, что nav).
  static const Color chipText = Color(0xFFFFFFFF);

  static const List<BoxShadow> lightNavShadows = [
    BoxShadow(
      color: Color(0x1E000000),
      blurRadius: 40,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> activeTabIndicatorShadows = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  /// Bottom nav: Refraction 100, Depth 16, Frost 7, fill black 40%.
  static final LiquidGlassSettings navBarGlass = LiquidGlassSettings.figma(
    refraction: 100,
    depth: 16,
    frost: 7,
    dispersion: 0,
    glassColor: navBarFill,
    lightAngle: math.pi / 4,
  );

  /// Чипы ленты: тот же вид, но через [LiquidGlassLayer.fake] (без shader).
  static final LiquidGlassSettings feedChipGlass = navBarGlass.copyWith(
    visibility: 0.85,
  );

  /// Чипы шапки — тот же glass, что [navBarGlass].
  static LiquidGlassSettings settingsFor(BuildContext context) {
    if (isLight(context)) {
      return navBarGlass;
    }
    return const LiquidGlassSettings(
      glassColor: Color(0x4DFFFFFF),
      blur: 10,
      thickness: 28,
      lightIntensity: 0.75,
      ambientStrength: 0.25,
      saturation: 1.5,
      chromaticAberration: 0.01,
      refractiveIndex: 1.24,
      lightAngle: math.pi / 4,
    );
  }
}
