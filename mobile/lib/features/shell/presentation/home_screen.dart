import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_colors.dart';

/// Стартовый экран — проверка токенов типографики и цветов.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Выходи', style: context.text18_600),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Социальные прогулки и события',
              style: context.textBody.copyWith(color: colors.caption),
            ),
            const SizedBox(height: AppSpacing.xl),
            _StyleRow(label: 'text-body', style: context.textBody),
            _StyleRow(label: 'text-15-450', style: context.text15_450),
            _StyleRow(label: 'text-13-400', style: context.text13_400),
            _StyleRow(label: 'text-14-550', style: context.text14_550),
            _StyleRow(label: 'text-18-600', style: context.text18_600),
            const SizedBox(height: AppSpacing.xl),
            Text('Цвета', style: context.text14_550),
            const SizedBox(height: AppSpacing.sm),
            _ColorSwatch(label: 'accent', color: colors.accent),
            _ColorSwatch(label: 'blue', color: colors.blue),
            _ColorSwatch(label: 'green', color: colors.green),
            _ColorSwatch(label: 'second-bg', color: colors.secondBackground),
          ],
        ),
      ),
    );
  }
}

class _StyleRow extends StatelessWidget {
  const _StyleRow({required this.label, required this.style});

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text13_400),
          const SizedBox(height: AppSpacing.xs),
          Text('Пример текста — The quick brown fox', style: style),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.appColors.caption.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: context.text13_400),
        ],
      ),
    );
  }
}
