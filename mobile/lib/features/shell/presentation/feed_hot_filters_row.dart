import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../core/theme/app_glass_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../ui/chips/glass_chip_button.dart';
import '../../../ui/layout/app_global_padding.dart';
import '../data/feed_filter_mock.dart';

/// Горизонтальный ряд горячих фильтров (glass).
///
/// Порядок: 1×1 → Группа → дивидер → формат/тема.
class FeedHotFiltersRow extends StatelessWidget {
  const FeedHotFiltersRow({
    super.key,
    required this.selectedIds,
    required this.onToggle,
  });

  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final afterDivider = FeedHotFilterMock.feedAfterDivider;

    return SizedBox(
      height: feedHotFilterChipRowHeight(),
      child: LiquidGlassLayer(
        settings: AppGlassTokens.feedChipGlass,
        useBackdropGroup: true,
        fake: true,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: AppGlobalPadding.padding(),
          clipBehavior: Clip.none,
          children: [
            for (final filter in FeedHotFilterMock.participationFilters) ...[
              GlassChipButton(
                label: filter.label,
                selected: selectedIds.contains(filter.id),
                onPressed: () => onToggle(filter.id),
              ),
              const SizedBox(width: AppSpacing.s8 - 2),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
              child: VerticalDivider(
                width: AppSpacing.s16,
                thickness: 1,
                color: colors.caption.withValues(alpha: 0.35),
              ),
            ),
            for (var i = 0; i < afterDivider.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s8 - 2),
              GlassChipButton(
                label: afterDivider[i].label,
                selected: selectedIds.contains(afterDivider[i].id),
                onPressed: () => onToggle(afterDivider[i].id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Высота ряда горячих чипов.
double feedHotFilterChipRowHeight() => GlassChipButton.height;
