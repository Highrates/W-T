import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_route_point.dart';
import 'event_route_map.dart';

/// Полноэкранная шторка с картой маршрута.
Future<void> showEventRouteMapSheet({
  required BuildContext context,
  required List<EventRoutePoint> points,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final colors = sheetContext.appColors;
      final mapHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.s8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.caption.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.paddingGlobal,
              AppSpacing.s16,
              AppSpacing.paddingGlobal,
              AppSpacing.s12,
            ),
            child: Text(
              'Маршрут',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingGlobal,
            ),
            child: EventRouteMap(
              points: points,
              height: mapHeight,
              deferPlatformView: false,
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(sheetContext).bottom + 12),
        ],
      );
    },
  );
}
