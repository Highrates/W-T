import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../ui/navigation/app_menu_sheet.dart';
import '../../application/create_route_controller.dart';
import '../../domain/create_route_join_mode.dart';

/// Шторка настроек группы: лимит и приём заявок.
Future<void> showCreateRouteGroupSheet({
  required BuildContext context,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.appColors.background,
    elevation: 0,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(kAppMenuSheetTopRadius),
      ),
    ),
    builder: (context) => const _CreateRouteGroupSheet(),
  );
}

class _CreateRouteGroupSheet extends ConsumerStatefulWidget {
  const _CreateRouteGroupSheet();

  @override
  ConsumerState<_CreateRouteGroupSheet> createState() =>
      _CreateRouteGroupSheetState();
}

class _CreateRouteGroupSheetState extends ConsumerState<_CreateRouteGroupSheet> {
  late int _maxParticipants;
  late CreateRouteJoinMode _joinMode;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(createRouteControllerProvider).draft;
    _maxParticipants = draft.maxParticipants ?? 6;
    if (_maxParticipants < 2) _maxParticipants = 2;
    _joinMode = draft.joinMode;
  }

  void _sync() {
    ref.read(createRouteControllerProvider.notifier).setParticipation(
          isOneOnOne: false,
          maxParticipants: _maxParticipants,
          joinMode: _joinMode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.paddingGlobal,
        AppSpacing.s16,
        AppSpacing.paddingGlobal,
        bottom + AppSpacing.s16,
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
          Text(
            'Группа',
            style: AppTextStyles.text18_600(color: colors.text),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Лимит участников: $_maxParticipants',
            style: AppTextStyles.text15_450(color: colors.text),
          ),
          Slider(
            min: 2,
            max: 20,
            divisions: 18,
            value: _maxParticipants.toDouble(),
            onChanged: (value) {
              setState(() => _maxParticipants = value.round());
              _sync();
            },
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Как принимать заявки',
            style: AppTextStyles.text15_450(color: colors.text),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: _JoinModeChip(
                  label: 'Автоматически',
                  selected: _joinMode == CreateRouteJoinMode.auto,
                  onTap: () {
                    setState(() => _joinMode = CreateRouteJoinMode.auto);
                    _sync();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: _JoinModeChip(
                  label: 'С подтверждением',
                  selected: _joinMode == CreateRouteJoinMode.approval,
                  onTap: () {
                    setState(() => _joinMode = CreateRouteJoinMode.approval);
                    _sync();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: colors.text,
                foregroundColor: colors.background,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Готово',
                style: AppTextStyles.text14_550(color: colors.background),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinModeChip extends StatelessWidget {
  const _JoinModeChip({
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
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s12,
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.text13_400(
                color: selected ? colors.background : colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
