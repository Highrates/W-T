import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../ui/navigation/app_menu_sheet.dart';
import '../../application/create_route_controller.dart';
import '../../domain/create_route_draft.dart';
import 'create_route_points_map.dart';

/// Шторка точек события (как участники на карточке).
Future<void> showCreateRoutePointsSheet({
  required BuildContext context,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.appColors.background,
    elevation: 0,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(kAppMenuSheetTopRadius),
      ),
    ),
    builder: (context) => const _CreateRoutePointsSheet(),
  );
}

class _CreateRoutePointsSheet extends ConsumerWidget {
  const _CreateRoutePointsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final draft = ref.watch(createRouteControllerProvider).draft;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.88;
    final canConfirm = draft.hasStartPoint;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.paddingGlobal,
          AppSpacing.s16,
          AppSpacing.paddingGlobal,
          bottom + AppSpacing.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Text(
              'Точки на карте',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Сначала старт. Тап по точке — описание. Промеж и финиш по желанию',
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
            const SizedBox(height: AppSpacing.s16),
            Expanded(
              child: CreateRoutePointsMap(draft: draft),
            ),
            const SizedBox(height: AppSpacing.s12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: canConfirm ? () => Navigator.of(context).pop() : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.text,
                  foregroundColor: colors.background,
                  disabledBackgroundColor:
                      colors.caption.withValues(alpha: 0.35),
                  disabledForegroundColor:
                      colors.background.withValues(alpha: 0.7),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Подтвердить',
                  style: AppTextStyles.text14_550(
                    color: canConfirm
                        ? colors.background
                        : colors.background.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка «Старт» под чипами — открывает шторку точек.
class CreateRoutePointsEntryRow extends StatelessWidget {
  const CreateRoutePointsEntryRow({
    super.key,
    required this.draft,
    required this.onTap,
  });

  final CreateRouteDraft draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final start = draft.startPoint;
    final title = start?.title.trim().isNotEmpty == true
        ? start!.title
        : 'Старт';
    final subtitle = draft.points.isEmpty
        ? 'Добавить точку на карте'
        : draft.points.length == 1
            ? '1 точка'
            : '${draft.points.length} точки';

    return Material(
      color: colors.secondBackground,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 22,
                color: draft.hasStartPoint ? colors.blue : colors.caption,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.text15_450(color: colors.text),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      subtitle,
                      style: AppTextStyles.text13_400(color: colors.caption),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
