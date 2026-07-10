import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/going_avatar_entries.dart';
import '../../../../shared/models/event_participant.dart';
import '../../../../ui/avatars/tappable_avatar.dart';
import '../../../cards/presentation/widgets/walk_card_participants_sheet.dart';
import '../../../profile/presentation/open_user_profile.dart';
import 'event_sheet_right_inset.dart';

class EventParticipantsSection extends StatelessWidget {
  const EventParticipantsSection({
    super.key,
    required this.goingLabel,
    required this.organizerId,
    required this.organizerAvatarAsset,
    required this.participants,
    this.avatarSize = 100,
  });

  final String goingLabel;
  final String organizerId;
  final String organizerAvatarAsset;
  final List<EventParticipant> participants;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final entries = buildGoingAvatarEntries(
      organizerId: organizerId,
      organizerAvatarAsset: organizerAvatarAsset,
      participants: participants,
    );
    final canOpenSheet = participants.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventSheetRightInset(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canOpenSheet
                  ? () => showWalkCardParticipantsSheet(
                        context: context,
                        goingLabel: goingLabel,
                        participants: participants,
                      )
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.r8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                child: Text(
                  goingLabel,
                  style: AppTextStyles.text18_600(color: colors.text),
                ),
              ),
            ),
          ),
        ),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: avatarSize,
                width: constraints.maxWidth + AppSpacing.paddingGlobal,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.s12),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return TappableAvatar(
                      avatarAsset: entry.avatarAsset,
                      size: avatarSize,
                      onTap: () => openUserProfile(context, entry.userId),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
