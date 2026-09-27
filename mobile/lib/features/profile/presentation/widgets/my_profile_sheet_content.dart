import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/profile_event_preview.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../ui/buttons/secondary_button.dart';
import '../../../../ui/icons/location_icon.dart';
import '../../../create_route/presentation/open_create_route.dart';
import '../../../event/presentation/open_event.dart';
import '../../../templates/domain/route_template_summary.dart';
import '../../../templates/presentation/template_spawn_sheet.dart';
import '../../../event/presentation/widgets/event_sheet_right_inset.dart';
import '../../domain/route_draft_summary.dart';
import 'profile_event_preview_card.dart';

class MyProfileSheetContent extends ConsumerStatefulWidget {
  const MyProfileSheetContent({
    super.key,
    required this.profile,
    required this.hostingUpcoming,
    required this.hostingPast,
    required this.goingUpcoming,
    required this.goingPast,
    required this.scrollController,
    required this.bottomPadding,
    this.routeDraft,
    this.templates = const [],
  });

  final UserProfile profile;
  final List<ProfileEventPreview> hostingUpcoming;
  final List<ProfileEventPreview>? hostingPast;
  final List<ProfileEventPreview> goingUpcoming;
  final List<ProfileEventPreview> goingPast;
  final RouteDraftSummary? routeDraft;
  final List<RouteTemplateSummary> templates;
  final ScrollController scrollController;
  final double bottomPadding;

  @override
  ConsumerState<MyProfileSheetContent> createState() =>
      _MyProfileSheetContentState();
}

class _MyProfileSheetContentState extends ConsumerState<MyProfileSheetContent> {
  var _pastExpanded = false;

  void _openEvent(String eventId, {required bool isPast}) {
    if (isPast) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Событие завершено')),
      );
      return;
    }
    openEvent(context, eventId);
  }

  void _placeholder(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _spawnTemplate(RouteTemplateSummary template) async {
    final scheduledAt = await pickTemplateSpawnSchedule(context, template);
    if (scheduledAt == null || !mounted) return;

    try {
      final eventId = await ref.read(templatesRepositoryProvider).spawnOccurrence(
            template.id,
            scheduledAt: scheduledAt,
          );
      if (!mounted || eventId.isEmpty) return;
      openEvent(context, eventId, justPublished: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось создать событие: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final profile = widget.profile;
    final pastHosting = widget.hostingPast ?? const [];
    final pastGoing = widget.goingPast;
    final hasPast = pastHosting.isNotEmpty || pastGoing.isNotEmpty;

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.paddingGlobal,
        18,
        0,
        widget.bottomPadding,
      ),
      children: [
        EventSheetRightInset(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  profile.name,
                  style: AppTextStyles.text18_600(color: colors.text),
                ),
              ),
              if (profile.isVerified)
                Icon(Icons.verified_rounded, size: 20, color: colors.blue),
            ],
          ),
        ),
        if (profile.city != null) ...[
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s4)),
          EventSheetRightInset(
            child: Row(
              children: [
                LocationIcon(
                  color: colors.caption,
                  variant: LocationIconVariant.line,
                ),
                const SizedBox(width: AppSpacing.gap6),
                Text(
                  profile.city!,
                  style: AppTextStyles.text14_550(color: colors.caption),
                ),
              ],
            ),
          ),
        ],
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s12)),
          EventSheetRightInset(
            child: Text(
              profile.bio!,
              style: AppTextStyles.text14_550(color: colors.text),
            ),
          ),
        ],
        if (profile.interestTags.isNotEmpty) ...[
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s12)),
          EventSheetRightInset(
            child: Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final tag in profile.interestTags)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.secondBackground,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s12,
                        vertical: AppSpacing.s4,
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.text13_400(color: colors.text),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const EventSheetRightInset(child: SizedBox(height: AppSpacing.s16)),
        EventSheetRightInset(
          child: SecondaryButton(
            label: 'Редактировать профиль',
            icon: const Icon(Icons.edit_outlined),
            expanded: true,
            onPressed: () => _placeholder('Редактирование профиля — скоро'),
          ),
        ),
        const EventSheetRightInset(child: SizedBox(height: AppSpacing.s16)),
        EventSheetRightInset(
          child: SecondaryButton(
            label: 'Создать событие',
            icon: const Icon(Icons.add_rounded),
            expanded: true,
            onPressed: () => openCreateRoute(context),
          ),
        ),
        const EventSheetRightInset(child: SizedBox(height: AppSpacing.s12)),
        EventSheetRightInset(
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Приглашения',
                  onPressed: () => _placeholder('Приглашения'),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: SecondaryButton(
                  label: 'Сохранённые',
                  onPressed: () => _placeholder('Сохранённые'),
                ),
              ),
            ],
          ),
        ),
        if (widget.routeDraft case final draft?) ...[
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s24)),
          EventSheetRightInset(
            child: Text(
              'Черновик',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          EventSheetRightInset(
            child: _RouteDraftCard(
              draft: draft,
              onContinue: () => openCreateRoute(context),
            ),
          ),
        ],
        if (widget.templates.isNotEmpty) ...[
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s24)),
          EventSheetRightInset(
            child: Text(
              'Шаблоны',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          for (final template in widget.templates)
            EventSheetRightInset(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: _TemplateCard(
                  template: template,
                  onSpawn: () => _spawnTemplate(template),
                ),
              ),
            ),
        ],
        if (widget.hostingUpcoming.isNotEmpty) ...[
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s24)),
          EventSheetRightInset(
            child: Text(
              'Веду',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
          ),
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s4)),
          EventSheetRightInset(
            child: Text(
              UserProfile.openEventsLabel(widget.hostingUpcoming.length),
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          _MyPageEventsRow(
            events: widget.hostingUpcoming,
            onEventTap: (id) => _openEvent(id, isPast: false),
          ),
        ],
        if (widget.goingUpcoming.isNotEmpty) ...[
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s24)),
          EventSheetRightInset(
            child: Text(
              'Иду',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
          ),
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s4)),
          EventSheetRightInset(
            child: Text(
              UserProfile.openEventsLabel(widget.goingUpcoming.length),
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          _MyPageEventsRow(
            events: widget.goingUpcoming,
            onEventTap: (id) => _openEvent(id, isPast: false),
          ),
        ],
        if (hasPast) ...[
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s24)),
          EventSheetRightInset(
            child: InkWell(
              onTap: () => setState(() => _pastExpanded = !_pastExpanded),
              borderRadius: BorderRadius.circular(AppRadius.r8),
              child: Row(
                children: [
                  Text(
                    'Было, но прошло',
                    style: AppTextStyles.text18_600(color: colors.text),
                  ),
                  const Spacer(),
                  Icon(
                    _pastExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.caption,
                  ),
                ],
              ),
            ),
          ),
          if (_pastExpanded) ...[
            if (pastHosting.isNotEmpty) ...[
              const EventSheetRightInset(child: SizedBox(height: AppSpacing.s12)),
              EventSheetRightInset(
                child: Text(
                  'Вёл(а)',
                  style: AppTextStyles.text14_550(color: colors.caption),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              _MyPageEventsRow(
                events: pastHosting,
                onEventTap: (id) => _openEvent(id, isPast: true),
              ),
            ],
            if (pastGoing.isNotEmpty) ...[
              const EventSheetRightInset(child: SizedBox(height: AppSpacing.s16)),
              EventSheetRightInset(
                child: Text(
                  'Ходил(а)',
                  style: AppTextStyles.text14_550(color: colors.caption),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              _MyPageEventsRow(
                events: pastGoing,
                onEventTap: (id) => _openEvent(id, isPast: true),
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onSpawn});

  final RouteTemplateSummary template;
  final VoidCallback onSpawn;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.secondBackground,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSpawn,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            children: [
              Icon(Icons.copy_all_outlined, color: colors.accent),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.text15_450(color: colors.text),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      '${template.pointCount} точек'
                      '${template.cityId != null ? ' · ${template.cityId}' : ''}',
                      style: AppTextStyles.text13_400(color: colors.caption),
                    ),
                  ],
                ),
              ),
              Text(
                'Создать',
                style: AppTextStyles.text13_400(color: colors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteDraftCard extends StatelessWidget {
  const _RouteDraftCard({
    required this.draft,
    required this.onContinue,
  });

  final RouteDraftSummary draft;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.secondBackground,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onContinue,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: colors.accent),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.text15_450(color: colors.text),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      '${draft.stepTitle}'
                      '${draft.pointCount > 0 ? ' · ${draft.pointCount} точек' : ''}',
                      style: AppTextStyles.text13_400(color: colors.caption),
                    ),
                  ],
                ),
              ),
              Text(
                'Продолжить',
                style: AppTextStyles.text13_400(color: colors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPageEventsRow extends StatelessWidget {
  const _MyPageEventsRow({
    required this.events,
    required this.onEventTap,
  });

  final List<ProfileEventPreview> events;
  final ValueChanged<String> onEventTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: ProfileEventPreviewCard.listHeight,
          width: constraints.maxWidth + AppSpacing.paddingGlobal,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
            itemBuilder: (context, index) {
              final preview = events[index];
              return ProfileEventPreviewCard(
                preview: preview,
                onTap: () => onEventTap(preview.eventId),
              );
            },
          ),
        );
      },
    );
  }
}
