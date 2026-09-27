import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../ui/navigation/app_menu_sheet.dart';
import '../data/reports_repository.dart';

Future<ReportReason?> pickReportReason(BuildContext context) {
  return showModalBottomSheet<ReportReason>(
    context: context,
    backgroundColor: context.appColors.background,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(kAppMenuSheetTopRadius),
      ),
    ),
    builder: (sheetContext) {
      final colors = sheetContext.appColors;

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
              Text(
                'Причина жалобы',
                style: AppTextStyles.text18_600(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.s12),
              for (final entry in _reasonLabels.entries)
                _ReportReasonRow(
                  label: entry.value,
                  onTap: () => Navigator.of(sheetContext).pop(entry.key),
                ),
            ],
          ),
        ),
      );
    },
  );
}

const _reasonLabels = {
  ReportReason.spam: 'Спам',
  ReportReason.inappropriate: 'Неприемлемый контент',
  ReportReason.harassment: 'Оскорбления / домогательства',
  ReportReason.fake: 'Фейк / обман',
  ReportReason.other: 'Другое',
};

class _ReportReasonRow extends StatelessWidget {
  const _ReportReasonRow({required this.label, required this.onTap});

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
          child: Text(
            label,
            style: AppTextStyles.text15_450(color: colors.text),
          ),
        ),
      ),
    );
  }
}
