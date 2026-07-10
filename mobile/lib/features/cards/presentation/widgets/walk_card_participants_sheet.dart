import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../ui/navigation/app_menu_sheet.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_participant.dart';
import '../../../profile/presentation/open_user_profile.dart';

/// Нижняя плашка: кто идёт на событие.
Future<void> showWalkCardParticipantsSheet({
  required BuildContext context,
  required String goingLabel,
  required List<EventParticipant> participants,
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
    builder: (context) {
      return _WalkCardParticipantsSheet(
        goingLabel: goingLabel,
        participants: participants,
      );
    },
  );
}

class _WalkCardParticipantsSheet extends StatelessWidget {
  const _WalkCardParticipantsSheet({
    required this.goingLabel,
    required this.participants,
  });

  final String goingLabel;
  final List<EventParticipant> participants;

  static const double _avatarSize = 72;
  static const double _rowGap = AppSpacing.s12;
  static const double _rowVerticalPadding = AppSpacing.s8;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.55;

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
            goingLabel,
            style: AppTextStyles.text18_600(color: colors.text),
          ),
          const SizedBox(height: AppSpacing.s16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: participants.length,
              separatorBuilder: (_, _) => const SizedBox(height: _rowGap),
              itemBuilder: (context, index) {
                final person = participants[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      openUserProfile(context, person.id);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: _rowVerticalPadding / 2,
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              person.avatarAsset,
                              width: _avatarSize,
                              height: _avatarSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Text(
                              person.name,
                              style: AppTextStyles.text18_600(
                                color: colors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
