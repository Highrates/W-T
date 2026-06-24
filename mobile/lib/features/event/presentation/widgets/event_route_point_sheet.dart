import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_route_point.dart';

/// Шторка с описанием и фото точки маршрута.
Future<void> showEventRoutePointSheet({
  required BuildContext context,
  required EventRoutePoint point,
  required int index,
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
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.paddingGlobal,
              AppSpacing.s8,
              AppSpacing.paddingGlobal,
              bottom + AppSpacing.s16,
            ),
            children: [
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
              const SizedBox(height: AppSpacing.s16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.secondBackground,
                    ),
                    child: Text(
                      '$index',
                      style: AppTextStyles.text14_550(color: colors.text),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.title,
                          style: AppTextStyles.text18_600(color: colors.text),
                        ),
                        if (point.detail != null) ...[
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            point.detail!,
                            style: AppTextStyles.text14_550(
                              color: colors.caption,
                            ),
                          ),
                        ],
                        if (point.address != null) ...[
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            point.address!,
                            style: AppTextStyles.text13_400(
                              color: colors.caption,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (point.description != null &&
                  point.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s16),
                Text(
                  point.description!,
                  style: AppTextStyles.text14_550(color: colors.text),
                ),
              ],
              for (final asset in point.photoAssets) ...[
                const SizedBox(height: AppSpacing.s12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                  child: Image.asset(
                    asset,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ],
            ],
          );
        },
      );
    },
  );
}
