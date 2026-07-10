import 'package:flutter/material.dart';

import '../../../../core/map/map_deferred_host.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_route_point.dart';
import '../../../../shared/models/geo_point.dart';
import '../../../../ui/map/app_map_pin.dart';
import '../../../../ui/map/app_yandex_map.dart';
import 'event_route_point_sheet.dart';

/// Карта маршрута: вехи (номер / фото) + линия между точками.
class EventRouteMap extends StatelessWidget {
  const EventRouteMap({
    super.key,
    required this.points,
    this.height = 240,
    this.deferStrategy = MapDeferStrategy.postFrame,
    this.onMapTap,
  });

  final List<EventRoutePoint> points;
  final double height;

  /// Отложенный mount platform view (ListView / sheet).
  final MapDeferStrategy deferStrategy;

  /// Тап по превью карты (открыть полноэкранную шторку).
  final VoidCallback? onMapTap;

  void _onPinTap(BuildContext context, AppMapPin pin) {
    final index = int.tryParse(pin.id ?? '');
    if (index == null || index < 1 || index > points.length) return;

    showEventRoutePointSheet(
      context: context,
      point: points[index - 1],
      index: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final located = [for (final point in points) point.location];

    final placeholder = SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.secondBackground,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Center(
          child: Text(
            'Загрузка карты…',
            style: AppTextStyles.text14_550(color: colors.caption),
          ),
        ),
      ),
    );

    final map = MapDeferredHost(
      strategy: deferStrategy,
      placeholder: placeholder,
      builder: (context) {
        return AppYandexMap(
          height: height,
          borderRadius: AppRadius.r12,
          showRoutePolyline: points.length >= 2,
          largeRouteMarkers: true,
          pins: [
            for (var i = 0; i < points.length; i++)
              AppMapPin(
                id: '${i + 1}',
                title: points[i].title,
                location: points[i].location,
                style: AppMapPinStyle.routeWaypoint,
                waypointIndex: i + 1,
                imageAsset: points[i].photoAssets.isNotEmpty
                    ? points[i].photoAssets.first
                    : null,
              ),
          ],
          initialCenter: GeoPoint.centroid(located),
          initialZoom: GeoPoint.zoomForSpread(located, fallback: 13),
          interactive: onMapTap == null,
          onPinTap: onMapTap == null ? (pin) => _onPinTap(context, pin) : null,
        );
      },
    );

    if (onMapTap == null) return map;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(child: map),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMapTap,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
