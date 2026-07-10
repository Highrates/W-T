import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../ui/buttons/primary_button_black.dart';
import '../../../ui/buttons/secondary_button.dart';

enum RouteTemplateRecurrence {
  none,
  weekly,
  biweekly,
  monthly,
}

/// Экран «Сделать шаблоном» — после публикации, вне wizard.
class RouteTemplateScreen extends ConsumerStatefulWidget {
  const RouteTemplateScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<RouteTemplateScreen> createState() =>
      _RouteTemplateScreenState();
}

class _RouteTemplateScreenState extends ConsumerState<RouteTemplateScreen> {
  RouteTemplateRecurrence _recurrence = RouteTemplateRecurrence.none;
  var _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Шаблон сохранён (mock)')),
    );
    context.go('/event/${widget.eventId}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Сделать шаблоном')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingGlobal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Повторение',
                style: AppTextStyles.text18_600(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Шаблон сохранит маршрут и описание. Дату вы будете '
                'задавать при каждом новом событии.',
                style: AppTextStyles.text13_400(color: colors.caption),
              ),
              const SizedBox(height: AppSpacing.s16),
              RadioListTile<RouteTemplateRecurrence>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Без повтора'),
                subtitle: const Text('Только как заготовка маршрута'),
                value: RouteTemplateRecurrence.none,
                groupValue: _recurrence,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _recurrence = value);
                },
              ),
              RadioListTile<RouteTemplateRecurrence>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Еженедельно'),
                value: RouteTemplateRecurrence.weekly,
                groupValue: _recurrence,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _recurrence = value);
                },
              ),
              RadioListTile<RouteTemplateRecurrence>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Раз в две недели'),
                value: RouteTemplateRecurrence.biweekly,
                groupValue: _recurrence,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _recurrence = value);
                },
              ),
              RadioListTile<RouteTemplateRecurrence>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ежемесячно'),
                value: RouteTemplateRecurrence.monthly,
                groupValue: _recurrence,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _recurrence = value);
                },
              ),
              const Spacer(),
              SecondaryButton(
                label: 'Пропустить',
                onPressed: _isSaving
                    ? null
                    : () => context.go('/event/${widget.eventId}'),
                expanded: true,
              ),
              const SizedBox(height: AppSpacing.s12),
              PrimaryButtonBlack(
                label: 'Сохранить шаблон',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
