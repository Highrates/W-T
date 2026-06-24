import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme_colors.dart';

/// Вариант иконки локации.
enum LocationIconVariant {
  /// Заливка — `nav/location.svg` (нижнее меню).
  filled,

  /// Контур — `nav/location-line.svg` (лента, профиль).
  line,
}

/// Иконка локации для чипов и строки города.
class LocationIcon extends StatelessWidget {
  const LocationIcon({
    super.key,
    this.size = 18,
    this.color,
    this.variant = LocationIconVariant.filled,
  });

  static const String filledAsset = 'assets/icons/nav/location.svg';
  static const String lineAsset = 'assets/icons/nav/location-line.svg';

  final double size;
  final Color? color;
  final LocationIconVariant variant;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.appColors.caption;

    if (variant == LocationIconVariant.line) {
      return SvgPicture.asset(
        lineAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      );
    }

    return SvgPicture.asset(
      filledAsset,
      width: size,
      height: size * (21 / 18),
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
    );
  }
}
