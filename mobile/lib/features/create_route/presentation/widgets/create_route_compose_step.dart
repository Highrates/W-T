import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../../core/theme/app_glass_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../shell/data/feed_filter_mock.dart';
import '../../../../ui/chips/glass_chip_button.dart';
import '../../application/create_route_controller.dart';
import '../../domain/create_route_draft.dart';
import 'create_route_date_format.dart';
import 'create_route_group_sheet.dart';
import 'create_route_photos_sheet.dart';
import 'create_route_points_sheet.dart';

/// Шаг 1: compose в духе Threads — тип, текст, теги, когда.
class CreateRouteComposeStep extends ConsumerStatefulWidget {
  const CreateRouteComposeStep({super.key, required this.draft});

  final CreateRouteDraft draft;

  @override
  ConsumerState<CreateRouteComposeStep> createState() =>
      _CreateRouteComposeStepState();
}

class _CreateRouteComposeStepState extends ConsumerState<CreateRouteComposeStep> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late bool _oneOnOne;
  late DateTime? _scheduledAt;

  static const _organizerAvatar = 'assets/images/people/04.jpg';
  static const double _avatarSize = 48;
  static const double _railWidth = 48;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.draft.title);
    _description = TextEditingController(text: widget.draft.description);
    _oneOnOne = widget.draft.isOneOnOne;
    _scheduledAt = widget.draft.scheduledAt ??
        DateTime.now().add(const Duration(hours: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAll());
  }

  @override
  void didUpdateWidget(CreateRouteComposeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.title != widget.draft.title &&
        _title.text != widget.draft.title) {
      _title.text = widget.draft.title;
    }
    if (oldWidget.draft.description != widget.draft.description &&
        _description.text != widget.draft.description) {
      _description.text = widget.draft.description;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  CreateRouteController get _controller =>
      ref.read(createRouteControllerProvider.notifier);

  void _syncBasics() {
    _controller.setBasics(
      title: _title.text,
      description: _description.text,
    );
  }

  void _syncParticipation() {
    final draft = ref.read(createRouteControllerProvider).draft;
    _controller.setParticipation(
      isOneOnOne: _oneOnOne,
      maxParticipants: _oneOnOne ? 2 : (draft.maxParticipants ?? 6),
      joinMode: _oneOnOne ? null : draft.joinMode,
    );
  }

  void _syncSchedule() {
    _controller.setSchedule(
      scheduledAt: _scheduledAt,
      hideExactTime: false,
    );
  }

  void _syncAll() {
    _syncBasics();
    _syncParticipation();
    _syncSchedule();
  }

  void _setOneOnOne(bool value) {
    if (_oneOnOne == value) return;
    setState(() => _oneOnOne = value);
    _syncParticipation();
  }

  Future<void> _onGroupTap() async {
    if (_oneOnOne) {
      setState(() => _oneOnOne = false);
      _syncParticipation();
    }
    if (!mounted) return;
    await showCreateRouteGroupSheet(context: context);
  }

  Future<void> _pickWhen() async {
    final initial = _scheduledAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      locale: const Locale('ru', 'RU'),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: initial,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
    _syncSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = _controller;
    final draft = widget.draft;
    final whenLabel = _scheduledAt != null
        ? formatCreateRouteWhen(_scheduledAt!)
        : 'Когда?';

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _railWidth,
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        _organizerAvatar,
                        width: _avatarSize,
                        height: _avatarSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s4,
                        ),
                        child: Center(
                          child: Container(
                            width: 1.5,
                            color: colors.caption.withValues(alpha: 0.28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: GlassChipButton.height,
                      child: LiquidGlassLayer(
                        settings: AppGlassTokens.feedChipGlass,
                        useBackdropGroup: true,
                        fake: true,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          children: [
                            GlassChipButton(
                              label: '🤝 1×1',
                              selected: _oneOnOne,
                              selectedShellColor: colors.blue,
                              selectedForegroundColor: colors.onImagePrimary,
                              showCheckmarkWhenSelected: true,
                              onPressed: () => _setOneOnOne(true),
                            ),
                            const SizedBox(width: AppSpacing.s8 - 2),
                            GlassChipButton(
                              label: '👥 Группа',
                              selected: !_oneOnOne,
                              selectedShellColor: colors.blue,
                              selectedForegroundColor: colors.onImagePrimary,
                              showCheckmarkWhenSelected: true,
                              onPressed: _onGroupTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    TextField(
                      controller: _title,
                      autofocus: draft.title.isEmpty,
                      style: AppTextStyles.text18_600(color: colors.text),
                      decoration: InputDecoration(
                        hintText: 'Название события',
                        hintStyle:
                            AppTextStyles.text18_600(color: colors.caption),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => _syncBasics(),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    TextField(
                      controller: _description,
                      style: AppTextStyles.text15_450(color: colors.text),
                      decoration: InputDecoration(
                        hintText:
                            'Описание — куда идём, что ждёт участников…',
                        hintStyle:
                            AppTextStyles.text15_450(color: colors.caption),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      minLines: 2,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => _syncBasics(),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickWhen,
                        borderRadius: BorderRadius.circular(AppSpacing.s8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.s8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: colors.caption,
                              ),
                              const SizedBox(width: AppSpacing.s8),
                              Expanded(
                                child: Text(
                                  whenLabel,
                                  style: AppTextStyles.text15_450(
                                    color: _scheduledAt != null
                                        ? colors.text
                                        : colors.caption,
                                  ),
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
                    ),
                    const SizedBox(height: AppSpacing.s32),
                    LiquidGlassLayer(
                      settings: AppGlassTokens.feedChipGlass,
                      useBackdropGroup: true,
                      fake: true,
                      child: Wrap(
                        spacing: AppSpacing.gap6,
                        runSpacing: AppSpacing.gap6,
                        children: [
                          for (final filter
                              in FeedHotFilterMock.createRouteAll)
                            GlassChipButton(
                              label: filter.label,
                              selected:
                                  draft.hotFilterIds.contains(filter.id),
                              selectedShellColor: colors.blue,
                              selectedForegroundColor: colors.onImagePrimary,
                              showCheckmarkWhenSelected: true,
                              simulatedGlass: true,
                              contentPadding: GlassChipButton.wizardPadding,
                              onPressed: () =>
                                  controller.toggleHotFilter(filter.id),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    CreateRoutePointsEntryRow(
                      draft: draft,
                      onTap: () => showCreateRoutePointsSheet(context: context),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    CreateRoutePhotosEntryRow(
                      draft: draft,
                      onTap: () => showCreateRoutePhotosSheet(context: context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
