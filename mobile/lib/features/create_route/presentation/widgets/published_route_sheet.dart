import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../ui/buttons/primary_button_black.dart';
import '../../../../ui/buttons/secondary_button.dart';
import '../../../../app/app_router.dart';

/// Bottom sheet после публикации: шаблон или просмотр маршрута.
Future<void> showPublishedRouteSheet({
  required BuildContext context,
  required String eventId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final colors = context.appColors;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.paddingGlobal,
          AppSpacing.s8,
          AppSpacing.paddingGlobal,
          MediaQuery.paddingOf(context).bottom + AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Маршрут опубликован',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Можно сразу посмотреть карточку или сохранить как шаблон '
              'для повторов.',
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
            const SizedBox(height: AppSpacing.s24),
            PrimaryButtonBlack(
              label: 'Посмотреть маршрут',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.s12),
            SecondaryButton(
              label: 'Сделать шаблоном',
              expanded: true,
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.routeTemplatePath(eventId));
              },
            ),
          ],
        ),
      );
    },
  );
}
