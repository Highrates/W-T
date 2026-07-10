import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../core/theme/app_glass_tokens.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../features/shell/data/feed_filter_mock.dart';
import '../../../features/shell/data/location_filter_mock.dart';
import '../../../ui/chips/glass_chip_button.dart';
import '../../../ui/icons/location_icon.dart';
import '../../../ui/dialogs/app_dialog.dart';
import '../data/create_route_sources_mock.dart';
import '../application/create_route_controller.dart';
import '../domain/create_route_draft.dart';
import '../domain/create_route_join_mode.dart';
import '../domain/create_route_source.dart';
import '../domain/create_route_step.dart';
import 'open_create_route.dart';
import 'widgets/create_route_point_details_step.dart';
import 'widgets/create_route_photos_step.dart';
import 'widgets/create_route_points_map.dart';
import 'widgets/create_route_review_step.dart';
import 'widgets/create_route_step_shell.dart';

/// Wizard создания маршрута (organizer flow).
class CreateRouteScreen extends ConsumerStatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  ConsumerState<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends ConsumerState<CreateRouteScreen> {
  String? _stepError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(createRouteControllerProvider.notifier).tryRestoreDraft(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(createRouteControllerProvider);
    final controller = ref.read(createRouteControllerProvider.notifier);
    final colors = context.appColors;
    final step = wizard.step;
    final stepIndex = CreateRouteStep.values.indexOf(step);
    final isLast = step == CreateRouteStep.review;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Создать маршрут'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.paddingGlobal,
              AppSpacing.s8,
              AppSpacing.paddingGlobal,
              AppSpacing.s16,
            ),
            child: CreateRouteStepShell(
              step: step,
              stepIndex: stepIndex,
              stepCount: CreateRouteStep.values.length,
              errorText: _stepError,
              onBack: stepIndex > 0
                  ? () {
                      setState(() => _stepError = null);
                      controller.goBack();
                    }
                  : null,
              primaryLabel: isLast ? 'Опубликовать' : 'Далее',
              isPrimaryLoading: wizard.isPublishing,
              onPrimary: () => _onPrimary(controller, isLast),
              child: _StepBody(step: step, draft: wizard.draft),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onPrimary(CreateRouteController controller, bool isLast) async {
    final error = controller.validateStep(
      ref.read(createRouteControllerProvider).step,
    );
    if (error != null) {
      setState(() => _stepError = error);
      return;
    }
    setState(() => _stepError = null);

    if (isLast) {
      final eventId = await controller.publish();
      if (!mounted || eventId == null) return;
      openPublishedEvent(context, eventId);
      return;
    }

    controller.goNext();
  }

  Future<void> _confirmExit(BuildContext context) async {
    final leave = await showAppDialog<bool>(
      context: context,
      title: 'Выйти из создания?',
      message:
          'Черновик сохраняется автоматически. Вы сможете продолжить '
          'из меню «Создать маршрут».',
      actions: const [
        AppDialogAction(
          label: 'Выйти',
          value: true,
          isPrimary: true,
        ),
        AppDialogAction(
          label: 'Остаться',
          value: false,
        ),
      ],
    );
    if (leave == true && context.mounted) {
      context.pop();
    }
  }
}

class _StepBody extends ConsumerWidget {
  const _StepBody({required this.step, required this.draft});

  final CreateRouteStep step;
  final CreateRouteDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (step) {
      CreateRouteStep.source => _SourceStep(draft: draft),
      CreateRouteStep.formatAndTheme => _FormatThemeStep(draft: draft),
      CreateRouteStep.basics => _BasicsStep(draft: draft),
      CreateRouteStep.schedule => _ScheduleStep(draft: draft),
      CreateRouteStep.routePoints => _RoutePointsStep(draft: draft),
      CreateRouteStep.pointDetails => CreateRoutePointDetailsStep(draft: draft),
      CreateRouteStep.photos => CreateRoutePhotosStep(draft: draft),
      CreateRouteStep.participation => _ParticipationStep(draft: draft),
      CreateRouteStep.review => CreateRouteReviewStep(draft: draft),
    };
  }
}

class _SourceStep extends ConsumerWidget {
  const _SourceStep({required this.draft});

  final CreateRouteDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(createRouteControllerProvider.notifier);
    final previous = CreateRouteSourcesMock.previousOptions;
    final templates = CreateRouteSourcesMock.templateOptions;

    return ListView(
      children: [
        _SourceTile(
          title: 'Новый маршрут',
          subtitle: 'С нуля, все поля заполните сами',
          selected: draft.source == CreateRouteSource.blank,
          onTap: () => controller.setSource(CreateRouteSource.blank),
        ),
        if (previous.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Из моих прошлых',
            style: AppTextStyles.text18_600(color: context.appColors.text),
          ),
          const SizedBox(height: AppSpacing.s8),
          for (final option in previous)
            _SourceOptionTile(
              option: option,
              selected: draft.sourceEventId == option.id &&
                  draft.source == CreateRouteSource.fromPrevious,
              onTap: () {
                controller.setSource(CreateRouteSource.fromPrevious);
                controller.selectSourceEvent(option.id);
              },
            ),
        ],
        if (templates.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Шаблоны',
            style: AppTextStyles.text18_600(color: context.appColors.text),
          ),
          const SizedBox(height: AppSpacing.s8),
          for (final option in templates)
            _SourceOptionTile(
              option: option,
              selected: draft.sourceEventId == option.id &&
                  draft.source == CreateRouteSource.fromTemplate,
              onTap: () {
                controller.setSource(CreateRouteSource.fromTemplate);
                controller.selectTemplate(option.id);
              },
            ),
        ],
      ],
    );
  }
}

class _FormatThemeStep extends ConsumerWidget {
  const _FormatThemeStep({required this.draft});

  final CreateRouteDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(createRouteControllerProvider.notifier);
    final colors = context.appColors;
    final selectedIds = draft.hotFilterIds;

    return ListView(
      children: [
        LiquidGlassLayer(
          settings: AppGlassTokens.feedChipGlass,
          useBackdropGroup: true,
          fake: true,
          child: Wrap(
            spacing: AppSpacing.s8 - 2,
            runSpacing: AppSpacing.s8 - 2,
            children: [
              for (final filter in FeedHotFilterMock.createRouteAll)
                GlassChipButton(
                  label: filter.label,
                  selected: selectedIds.contains(filter.id),
                  selectedShellColor: colors.blue,
                  selectedForegroundColor: colors.onImagePrimary,
                  showCheckmarkWhenSelected: true,
                  simulatedGlass: true,
                  contentPadding: GlassChipButton.wizardPadding,
                  onPressed: () => controller.toggleHotFilter(filter.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BasicsStep extends ConsumerStatefulWidget {
  const _BasicsStep({required this.draft});

  final CreateRouteDraft draft;

  @override
  ConsumerState<_BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends ConsumerState<_BasicsStep> {
  late final TextEditingController _title;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.draft.title);
    _description = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _clearDescriptionInDraft());
  }

  @override
  void didUpdateWidget(_BasicsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.title != widget.draft.title &&
        _title.text != widget.draft.title) {
      _title.text = widget.draft.title;
    }
  }

  void _clearDescriptionInDraft() {
    if (!mounted) return;
    final draft = ref.read(createRouteControllerProvider).draft;
    if (draft.description.isEmpty) return;
    ref.read(createRouteControllerProvider.notifier).setBasics(
          title: draft.title,
          description: '',
        );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _sync() {
    ref.read(createRouteControllerProvider.notifier).setBasics(
          title: _title.text,
          description: _description.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final startCity = widget.draft.startPoint?.cityId ?? widget.draft.cityId;
    final cityLabel = _cityLabel(startCity);

    return ListView(
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Название'),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextField(
          controller: _description,
          decoration: const InputDecoration(
            labelText: 'Описание',
            alignLabelWithHint: true,
          ),
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: AppSpacing.s16),
        if (widget.draft.hasStartPoint)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: LocationIcon(
              color: colors.caption,
              variant: LocationIconVariant.line,
            ),
            title: Text('Город маршрута: $cityLabel'),
            subtitle: const Text('Определяется по точке старта'),
          )
        else
          Text(
            'Город маршрута определяется автоматически по точке старта '
            'на следующем шаге.',
            style: AppTextStyles.text13_400(color: colors.caption),
          ),
      ],
    );
  }

  String _cityLabel(String cityId) {
    for (final city in LocationFilterMock.cityOptions) {
      if (city.id == cityId) return city.label;
    }
    return cityId;
  }
}

class _ScheduleStep extends ConsumerStatefulWidget {
  const _ScheduleStep({required this.draft});

  final CreateRouteDraft draft;

  @override
  ConsumerState<_ScheduleStep> createState() => _ScheduleStepState();
}

class _ScheduleStepState extends ConsumerState<_ScheduleStep> {
  DateTime? _dateTime;
  bool _hideExactTime = false;

  @override
  void initState() {
    super.initState();
    _dateTime = widget.draft.scheduledAt ?? DateTime.now().add(const Duration(hours: 2));
    _hideExactTime = widget.draft.hideExactTime;
    _sync();
  }

  void _sync() {
    ref.read(createRouteControllerProvider.notifier).setSchedule(
          scheduledAt: _dateTime,
          hideExactTime: _hideExactTime,
        );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ru', 'RU'),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _dateTime ?? DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime?.hour ?? 12,
        _dateTime?.minute ?? 0,
      );
    });
    _sync();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime ?? DateTime.now()),
    );
    if (picked == null) return;
    final base = _dateTime ?? DateTime.now();
    setState(() {
      _dateTime = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
    });
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dateLabel =
        _dateTime != null ? _formatDate(_dateTime!) : 'Не выбрано';
    final timeLabel =
        _dateTime != null ? _formatTime(_dateTime!) : 'Не выбрано';

    return ListView(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Дата'),
          subtitle: Text(dateLabel),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: _pickDate,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Время'),
          subtitle: Text(timeLabel),
          trailing: const Icon(Icons.schedule),
          onTap: _pickTime,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Скрыть точное время'),
          subtitle: const Text('В ленте будет «Сегодня» без минут'),
          value: _hideExactTime,
          onChanged: (value) {
            setState(() => _hideExactTime = value);
            _sync();
          },
        ),
      ],
    );
  }
}

class _RoutePointsStep extends StatelessWidget {
  const _RoutePointsStep({required this.draft});

  final CreateRouteDraft draft;

  @override
  Widget build(BuildContext context) {
    return CreateRoutePointsMap(draft: draft);
  }
}

class _ParticipationStep extends ConsumerStatefulWidget {
  const _ParticipationStep({required this.draft});

  final CreateRouteDraft draft;

  @override
  ConsumerState<_ParticipationStep> createState() => _ParticipationStepState();
}

class _ParticipationStepState extends ConsumerState<_ParticipationStep> {
  late bool _oneOnOne;
  late int _maxParticipants;
  late CreateRouteJoinMode _joinMode;

  @override
  void initState() {
    super.initState();
    _oneOnOne = widget.draft.isOneOnOne;
    _maxParticipants = widget.draft.maxParticipants ?? 6;
    _joinMode = widget.draft.joinMode;
    _sync();
  }

  void _sync({CreateRouteJoinMode? joinMode}) {
    ref.read(createRouteControllerProvider.notifier).setParticipation(
          isOneOnOne: _oneOnOne,
          maxParticipants: _oneOnOne ? 2 : _maxParticipants,
          joinMode: joinMode ?? _joinMode,
        );
  }

  void _setFormat({required bool oneOnOne}) {
    if (_oneOnOne == oneOnOne) return;
    setState(() => _oneOnOne = oneOnOne);
    _sync();
  }

  void _setJoinMode(CreateRouteJoinMode mode) {
    if (_joinMode == mode) return;
    setState(() => _joinMode = mode);
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: _ParticipationChip(
                label: '1×1',
                selected: _oneOnOne,
                onTap: () => _setFormat(oneOnOne: true),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: _ParticipationChip(
                label: 'Группа',
                selected: !_oneOnOne,
                onTap: () => _setFormat(oneOnOne: false),
              ),
            ),
          ],
        ),
        if (!_oneOnOne) ...[
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Лимит участников: $_maxParticipants',
            style: AppTextStyles.text15_450(color: colors.text),
          ),
          Slider(
            min: 2,
            max: 20,
            divisions: 18,
            label: '$_maxParticipants',
            value: _maxParticipants.toDouble(),
            onChanged: (value) {
              setState(() => _maxParticipants = value.round());
              _sync();
            },
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
        Text(
          'Как принимать заявки',
          style: AppTextStyles.text18_600(color: colors.text),
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(
              child: _ParticipationChip(
                label: 'Автоматически',
                selected: _joinMode == CreateRouteJoinMode.auto,
                onTap: () => _setJoinMode(CreateRouteJoinMode.auto),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: _ParticipationChip(
                label: 'С подтверждением',
                selected: _joinMode == CreateRouteJoinMode.approval,
                onTap: () => _setJoinMode(CreateRouteJoinMode.approval),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _formatDate(DateTime value) {
  const months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];
  final month = months[value.month - 1];
  return '${value.day} $month ${value.year}';
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _ParticipationChip extends StatelessWidget {
  const _ParticipationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: selected ? colors.text : colors.secondBackground,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s12,
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.text14_550(
                color: selected ? colors.background : colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: selected ? colors.secondBackground : colors.background,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(
              color: selected
                  ? colors.text
                  : colors.caption.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.text18_600(color: colors.text)),
              const SizedBox(height: AppSpacing.s4),
              Text(
                subtitle,
                style: AppTextStyles.text13_400(color: colors.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceOptionTile extends StatelessWidget {
  const _SourceOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  static const double _thumbSize = 80;
  static const double _cardInset = AppSpacing.s4;

  final CreateRouteSourceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Material(
        color: selected ? colors.secondBackground : colors.background,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: Container(
            padding: const EdgeInsets.all(_cardInset),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              border: Border.all(
                color: selected ? colors.text : colors.borderSubtle,
                width: selected ? 1 : 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (option.coverAsset != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                    child: SizedBox(
                      width: _thumbSize,
                      height: _thumbSize,
                      child: Image.asset(
                        option.coverAsset!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s12,
                      AppSpacing.s4,
                      AppSpacing.s8,
                      AppSpacing.s4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: AppTextStyles.text18_600(color: colors.text),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          option.subtitle,
                          style: AppTextStyles.text13_400(
                            color: colors.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
