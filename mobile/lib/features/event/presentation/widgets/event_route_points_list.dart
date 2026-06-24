import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_route_point.dart';
import 'event_expandable_route_point.dart';

class EventRoutePointsList extends StatelessWidget {
  const EventRoutePointsList({super.key, required this.points});

  final List<EventRoutePoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Точки маршрута',
          style: AppTextStyles.text18_600(color: colors.text),
        ),
        const SizedBox(height: AppSpacing.s16),
        for (var i = 0; i < points.length; i++)
          EventExpandableRoutePoint(
            index: i + 1,
            point: points[i],
            isLast: i == points.length - 1,
            initiallyExpanded: i == 0,
          ),
      ],
    );
  }
}
