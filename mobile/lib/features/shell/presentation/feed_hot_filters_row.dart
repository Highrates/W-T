import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../core/theme/app_glass_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../ui/chips/glass_chip_button.dart';
import '../../../ui/layout/app_global_padding.dart';
import '../data/feed_filter_mock.dart';

/// Горизонтальный ряд горячих фильтров (glass).
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
    return SizedBox(
      height: feedHotFilterChipRowHeight(),
      child: LiquidGlassLayer(
        settings: AppGlassTokens.feedChipGlass,
        useBackdropGroup: true,
        fake: true,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: AppGlobalPadding.padding(),
          clipBehavior: Clip.none,
          itemCount: FeedHotFilterMock.all.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8 - 2),
          itemBuilder: (context, index) {
            final filter = FeedHotFilterMock.all[index];
            final selected = selectedIds.contains(filter.id);
            return GlassChipButton(
              label: filter.label,
              selected: selected,
              onPressed: () => onToggle(filter.id),
            );
          },
        ),
      ),
    );
  }
}

/// Высота ряда горячих чипов.
double feedHotFilterChipRowHeight() => GlassChipButton.height;
