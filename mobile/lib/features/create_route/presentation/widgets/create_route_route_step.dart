import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/create_route_draft.dart';
import 'create_route_date_format.dart';
import 'create_route_points_map.dart';

/// Шаг 2: карта + компактное превью compose.
class CreateRouteRouteStep extends StatelessWidget {
  const CreateRouteRouteStep({super.key, required this.draft});

  final CreateRouteDraft draft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComposePreviewStrip(draft: draft),
        const SizedBox(height: AppSpacing.s12),
        Expanded(child: CreateRoutePointsMap(draft: draft)),
      ],
    );
  }
}

class _ComposePreviewStrip extends StatelessWidget {
  const _ComposePreviewStrip({required this.draft});

  final CreateRouteDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final when = draft.scheduledAt != null
        ? formatCreateRouteWhen(draft.scheduledAt!)
        : 'Без даты';
    final formatLabel = draft.isOneOnOne ? '1×1' : 'Группа';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondBackground,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.title.isEmpty ? 'Без названия' : draft.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.text15_450(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '$formatLabel · $when',
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
          ],
        ),
      ),
    );
  }
}
