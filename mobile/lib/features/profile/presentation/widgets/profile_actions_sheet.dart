import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/require_auth.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../ui/navigation/app_menu_sheet.dart';
import '../../../reports/presentation/report_reason_sheet.dart';

Future<void> showProfileActionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String targetUserId,
  required String profileName,
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    if (!await requireAuth(context)) return;
                    final reason = await pickReportReason(context);
                    if (reason == null || !context.mounted) return;
                    try {
                      await ref.read(reportsRepositoryProvider).submitReport(
                            targetUserId: targetUserId,
                            reason: reason,
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Жалоба на $profileName отправлена')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s12,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 24, color: colors.text),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Text(
                            'Пожаловаться',
                            style: AppTextStyles.text18_600(color: colors.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
