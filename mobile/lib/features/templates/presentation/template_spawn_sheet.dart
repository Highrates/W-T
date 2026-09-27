import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../ui/buttons/primary_button_black.dart';
import '../../../ui/navigation/app_menu_sheet.dart';
import '../domain/route_template_summary.dart';

Future<DateTime?> pickTemplateSpawnSchedule(
  BuildContext context,
  RouteTemplateSummary template,
) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appColors.background,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(kAppMenuSheetTopRadius),
      ),
    ),
    builder: (sheetContext) => _TemplateSpawnSheet(template: template),
  );
}

class _TemplateSpawnSheet extends StatefulWidget {
  const _TemplateSpawnSheet({required this.template});

  final RouteTemplateSummary template;

  @override
  State<_TemplateSpawnSheet> createState() => _TemplateSpawnSheetState();
}

class _TemplateSpawnSheetState extends State<_TemplateSpawnSheet> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day + 1, 10);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selected),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selected = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final formatted =
        MaterialLocalizations.of(context).formatFullDate(_selected);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.paddingGlobal,
          right: AppSpacing.paddingGlobal,
          top: AppSpacing.s16,
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.template.title,
              style: AppTextStyles.text18_600(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '${widget.template.pointCount} точек'
              '${widget.template.cityId != null ? ' · ${widget.template.cityId}' : ''}',
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
            const SizedBox(height: AppSpacing.s16),
            OutlinedButton(
              onPressed: _pickDateTime,
              child: Text('$formatted, ${TimeOfDay.fromDateTime(_selected).format(context)}'),
            ),
            const SizedBox(height: AppSpacing.s16),
            SizedBox(
              width: double.infinity,
              child: PrimaryButtonBlack(
                label: 'Создать событие',
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
