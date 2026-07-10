import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_route_metric.dart';

/// Иконка + метрика маршрута, как в шапке [WalkCard].
class EventRouteMetricRow extends StatelessWidget {
  const EventRouteMetricRow({
    super.key,
    required this.metric,
    required this.label,
  });

  final EventRouteMetric metric;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final icon = switch (metric) {
      EventRouteMetric.points => (
        asset: 'assets/icons/common/mappin.svg',
        width: 13.0,
        height: 16.0,
      ),
      EventRouteMetric.distance => (
        asset: 'assets/icons/common/rote.svg',
        width: 14.0,
        height: 14.0,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          icon.asset,
          width: icon.width,
          height: icon.height,
          colorFilter: ColorFilter.mode(colors.caption, BlendMode.srcIn),
        ),
        const SizedBox(width: AppSpacing.s4),
        Text(
          label,
          style: AppTextStyles.text14_550(color: colors.text),
        ),
      ],
    );
  }
}
