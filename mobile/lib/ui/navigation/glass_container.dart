import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

/// Полупрозрачный «стеклянный» контейнер (blur + заливка).
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.width,
    this.height,
    this.blurSigma = 24,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.br16;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fill = isDark
        ? const Color(0xFF3A3A3A).withValues(alpha: 0.55)
        : const Color(0xFFB8B8B8).withValues(alpha: 0.45);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.55);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: border, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
