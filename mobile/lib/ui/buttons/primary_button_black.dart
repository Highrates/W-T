import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'primary_button_base.dart';

/// Primary CTA: bg black, text white.
class PrimaryButtonBlack extends StatelessWidget {
  const PrimaryButtonBlack({
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
    return PrimaryButtonBase(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: AppPalette.lightText,
      textColor: AppPalette.lightBackground,
    );
  }
}
