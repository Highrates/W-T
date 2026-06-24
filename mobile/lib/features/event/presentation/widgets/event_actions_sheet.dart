import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../ui/navigation/app_menu_sheet.dart';

/// Действия в шапке мероприятия: поделиться, пожаловаться.
Future<void> showEventActionsSheet({
  required BuildContext context,
  required String eventTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.appColors.background,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(kAppMenuSheetTopRadius),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.paddingGlobal,
            AppSpacing.s16,
            AppSpacing.paddingGlobal,
            AppSpacing.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetContext.appColors.caption
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              _EventActionRow(
                icon: Icons.ios_share_rounded,
                label: 'Поделиться',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Поделиться: $eventTitle')),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.s12),
              _EventActionRow(
                icon: Icons.flag_outlined,
                label: 'Пожаловаться',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Жалоба отправлена')),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _EventActionRow extends StatelessWidget {
  const _EventActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
          child: Row(
            children: [
              Icon(icon, size: 24, color: colors.text),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.text18_600(color: colors.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
