import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

/// Общая разметка primary-кнопок (py-20, px-98, radius-16).
class PrimaryButtonBase extends StatelessWidget {
  const PrimaryButtonBase({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 98,
    vertical: 20,
  );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Material(
      color: backgroundColor,
      borderRadius: AppRadius.br16,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: AppRadius.br16,
        child: Padding(
          padding: padding,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Text(
                    label,
                    style: AppTextStyles.text18_600(color: textColor),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }
}
