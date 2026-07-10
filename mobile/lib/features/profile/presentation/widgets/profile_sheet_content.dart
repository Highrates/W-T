import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/profile_event_preview.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../ui/icons/location_icon.dart';
import '../../../event/presentation/widgets/event_sheet_right_inset.dart';
import 'profile_event_preview_card.dart';

class ProfileSheetContent extends StatelessWidget {
  const ProfileSheetContent({
    super.key,
    required this.profile,
    required this.scrollController,
    required this.bottomPadding,
    required this.onUpcomingEventTap,
    required this.onPastEventTap,
  });

  final UserProfile profile;
  final ScrollController scrollController;
  final double bottomPadding;
  final ValueChanged<String> onUpcomingEventTap;
  final ValueChanged<String> onPastEventTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final upcoming = profile.upcomingEvents;
    final past = profile.pastEvents;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.paddingGlobal,
        18,
        0,
        bottomPadding,
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
        if (upcoming.isNotEmpty) ...[
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s24)),
          EventSheetRightInset(
            child: Text(
              'Предстоящие события',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
          ),
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s4)),
          EventSheetRightInset(
            child: Text(
              UserProfile.openEventsLabel(upcoming.length),
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ProfileEventsRow(
            events: upcoming,
            onEventTap: onUpcomingEventTap,
          ),
        ],
        if (past != null && past.isNotEmpty) ...[
          const EventSheetRightInset(child: SizedBox(height: AppSpacing.s24)),
          EventSheetRightInset(
            child: Text(
              'Прошедшие события',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ProfileEventsRow(
            events: past,
            onEventTap: onPastEventTap,
          ),
        ],
      ],
    );
  }
}

/// Горизонтальная лента карточек — уходит за правый край, как аватары на событии.
class _ProfileEventsRow extends StatelessWidget {
  const _ProfileEventsRow({
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
