import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../ui/media/cover_image.dart';
import '../../../ui/navigation/app_menu_sheet.dart';
import '../application/participation_controller.dart';
import '../domain/event_participation.dart';

Future<void> showEventOrganizerParticipantsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String eventId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appColors.background,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(kAppMenuSheetTopRadius),
      ),
    ),
    builder: (sheetContext) {
      return _OrganizerParticipantsSheet(eventId: eventId);
    },
  );
}

class _OrganizerParticipantsSheet extends ConsumerStatefulWidget {
  const _OrganizerParticipantsSheet({required this.eventId});

  final String eventId;

  @override
  ConsumerState<_OrganizerParticipantsSheet> createState() =>
      _OrganizerParticipantsSheetState();
}

class _OrganizerParticipantsSheetState
    extends ConsumerState<_OrganizerParticipantsSheet> {
  late Future<List<EventParticipation>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref
        .read(participationControllerProvider.notifier)
        .listParticipations(widget.eventId);
  }

  Future<void> _decide(EventParticipation item, {required bool accept}) async {
    try {
      await ref.read(participationControllerProvider.notifier).updateParticipation(
            widget.eventId,
            item.id,
            accept: accept,
          );
      if (!mounted) return;
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
              'Заявки на участие',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s12),
            FutureBuilder<List<EventParticipation>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.s24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Ошибка: ${snapshot.error}',
                    style: AppTextStyles.text14_550(color: colors.caption),
                  );
                }

                final items = snapshot.data ?? const [];
                final pending = items.where((item) => item.isPending).toList();
                final accepted =
                    items.where((item) => item.status == 'accepted').toList();

                if (items.isEmpty) {
                  return Text(
                    'Пока нет заявок',
                    style: AppTextStyles.text14_550(color: colors.caption),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (pending.isNotEmpty) ...[
                          Text(
                            'Ожидают решения',
                            style: AppTextStyles.text14_550(color: colors.caption),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          for (final item in pending)
                            _ParticipationRow(
                              item: item,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Отклонить',
                                    onPressed: () => _decide(item, accept: false),
                                    icon: Icon(Icons.close_rounded, color: colors.caption),
                                  ),
                                  IconButton(
                                    tooltip: 'Принять',
                                    onPressed: () => _decide(item, accept: true),
                                    icon: Icon(Icons.check_rounded, color: colors.green),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if (accepted.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            'Участники',
                            style: AppTextStyles.text14_550(color: colors.caption),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          for (final item in accepted)
                            _ParticipationRow(item: item),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipationRow extends StatelessWidget {
  const _ParticipationRow({required this.item, this.trailing});

  final EventParticipation item;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final avatar = item.avatarAsset;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Material(
        color: colors.secondBackground,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.r8),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: avatar != null
                      ? CoverImage(ref: avatar, fit: BoxFit.cover)
                      : ColoredBox(
                          color: colors.background,
                          child: Icon(Icons.person_outline, color: colors.caption),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  item.name,
                  style: AppTextStyles.text15_450(color: colors.text),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
