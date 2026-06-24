import 'package:flutter/material.dart';

/// Сырые цвета палитры (Figma).
abstract final class AppPalette {
  // Light
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF000000);
  static const Color lightSecondBackground = Color(0xFFF2F3F4);
  static const Color lightFeedBackground = Color(0xFFF2F3F4);
  static const Color lightCaption = Color(0xFFA1A1A1);
  static const Color lightAccent = Color(0xFFFF423E);

  // Dark
  static const Color darkBackground = Color(0xFF111111);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSecondBackground = Color(0xFF232323);
  static const Color darkFeedBackground = Color(0xFF1A1A1A);
  static const Color darkCaption = Color(0xFF747373);
  static const Color darkAccent = Color(0xFFFF0000);

  // Shared
  static const Color blue = Color(0xFF00A8FE);
  static const Color green = Color(0xFF00D652);
  static const Color heroBackdrop = Color(0xFF000000);
  static const Color onImagePrimary = Color(0xFFFFFFFF);
}
