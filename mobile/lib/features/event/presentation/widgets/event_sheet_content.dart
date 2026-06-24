import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_detail_data.dart';
import '../../../../shared/models/walk_card_route_metric.dart';
import '../../../../ui/organizer/organizer_row.dart';
import 'event_participants_section.dart';
import 'event_route_map.dart';
import 'event_route_map_sheet.dart';
import 'event_route_metric_row.dart';
import 'event_route_points_list.dart';
import 'event_sheet_right_inset.dart';

class EventSheetContent extends StatelessWidget {
  const EventSheetContent({
    super.key,
    required this.data,
    required this.scrollController,
    required this.bottomPadding,
    required this.onOrganizerTap,
    this.goingAvatarSize = 100,
  });

  final EventDetailData data;
  final ScrollController scrollController;
  final double bottomPadding;
  final VoidCallback onOrganizerTap;
  final double goingAvatarSize;

  @override
  Widget build(BuildContext context) {
    final event = data.event;
    final colors = context.appColors;

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
          child: OrganizerRow(
            name: event.organizerName,
            avatarAsset: event.organizerAvatarAsset,
            isVerified: event.isOrganizerVerified,
            onTap: onOrganizerTap,
          ),
        ),
        const EventSheetRightInset(child: SizedBox(height: AppSpacing.s16)),
        EventSheetRightInset(
          child: Text(
            event.title,
            style: AppTextStyles.text18_600(color: colors.text),
          ),
        ),
        const EventSheetRightInset(child: SizedBox(height: 6)),
        EventSheetRightInset(
          child: Text(
            event.description,
            style: AppTextStyles.text14_550(color: colors.text),
          ),
        ),
        const EventSheetRightInset(child: SizedBox(height: AppSpacing.s24)),
        EventParticipantsSection(
          goingLabel: event.goingLabel,
          organizerId: event.organizerId,
          organizerAvatarAsset: event.organizerAvatarAsset,
          participants: event.participants,
          avatarSize: goingAvatarSize,
        ),
        const EventSheetRightInset(child: SizedBox(height: AppSpacing.s24)),
        EventSheetRightInset(
          child: _RouteSectionHeader(
            metric: event.routeMetric,
            metricLabel: event.routeMetricLabel,
            onTap: () => showEventRouteMapSheet(
              context: context,
              points: data.routePoints,
            ),
          ),
        ),
        const EventSheetRightInset(child: SizedBox(height: AppSpacing.s12)),
        EventRouteMap(
          points: data.routePoints,
          onMapTap: () => showEventRouteMapSheet(
            context: context,
            points: data.routePoints,
          ),
        ),
        const EventSheetRightInset(child: SizedBox(height: AppSpacing.s24)),
        EventSheetRightInset(
          child: EventRoutePointsList(points: data.routePoints),
        ),
      ],
    );
  }
}

class _RouteSectionHeader extends StatelessWidget {
  const _RouteSectionHeader({
    required this.metric,
    required this.metricLabel,
    required this.onTap,
  });

  final WalkCardRouteMetric metric;
  final String metricLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Маршрут',
                  style: AppTextStyles.text18_600(color: colors.text),
                ),
              ),
              EventRouteMetricRow(metric: metric, label: metricLabel),
              const SizedBox(width: AppSpacing.s4),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.caption,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
