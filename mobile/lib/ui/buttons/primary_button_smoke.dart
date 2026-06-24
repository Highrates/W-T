import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import 'primary_button_base.dart';

/// Primary CTA: bg second-bg, text black (semantic `text` в dark).
class PrimaryButtonSmoke extends StatelessWidget {
  const PrimaryButtonSmoke({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PrimaryButtonBase(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: colors.secondBackground,
      textColor: colors.text,
    );
  }
}
