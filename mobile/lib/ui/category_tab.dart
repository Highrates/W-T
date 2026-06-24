import 'package:flutter/material.dart';

import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme_colors.dart';

/// Таб категории (Пешком / Авто / …).
class CategoryTab extends StatelessWidget {
  const CategoryTab({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s12,
    vertical: AppSpacing.s12,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final backgroundColor =
        selected ? colors.secondBackground : colors.background;
    final textColor = selected ? colors.text : colors.caption;

    return Material(
      color: backgroundColor,
      borderRadius: AppRadius.br12,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.br12,
        child: Padding(
          padding: _padding,
          child: Text(
            label,
            style: AppTextStyles.text14_550(color: textColor),
          ),
        ),
      ),
    );
  }
}
