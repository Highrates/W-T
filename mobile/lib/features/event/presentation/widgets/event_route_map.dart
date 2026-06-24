import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/event_route_point.dart';
import '../../../../shared/models/geo_point.dart';
import '../../../../ui/map/app_map_pin.dart';
import '../../../../ui/map/app_yandex_map.dart';
import 'event_route_point_sheet.dart';

/// Карта маршрута: вехи (номер / фото) + линия между точками.
class EventRouteMap extends StatefulWidget {
  const EventRouteMap({
    super.key,
    required this.points,
    this.height = 240,
    this.deferPlatformView = true,
    this.onMapTap,
  });

  final List<EventRoutePoint> points;
  final double height;

  /// В ListView platform view создаём с задержкой (иначе не рисуется).
  final bool deferPlatformView;

  /// Тап по превью карты (открыть полноэкранную шторку).
  final VoidCallback? onMapTap;

  @override
  State<EventRouteMap> createState() => _EventRouteMapState();
}

class _EventRouteMapState extends State<EventRouteMap> {
  bool _platformViewReady = false;

  @override
  void initState() {
    super.initState();
    if (!widget.deferPlatformView) {
      _platformViewReady = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _platformViewReady = true);
    });
  }

  void _onPinTap(AppMapPin pin) {
    final index = int.tryParse(pin.id ?? '');
    if (index == null || index < 1 || index > widget.points.length) return;

    showEventRoutePointSheet(
      context: context,
      point: widget.points[index - 1],
      index: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final located = [for (final point in widget.points) point.location];

    final map = _platformViewReady
        ? AppYandexMap(
            height: widget.height,
            borderRadius: AppRadius.r12,
            showRoutePolyline: widget.points.length >= 2,
            largeRouteMarkers: true,
            pins: [
              for (var i = 0; i < widget.points.length; i++)
                AppMapPin(
                  id: '${i + 1}',
                  title: widget.points[i].title,
                  location: widget.points[i].location,
                  style: AppMapPinStyle.routeWaypoint,
                  waypointIndex: i + 1,
                  imageAsset: widget.points[i].photoAssets.isNotEmpty
                      ? widget.points[i].photoAssets.first
                      : null,
                ),
            ],
            initialCenter: GeoPoint.centroid(located),
            initialZoom: GeoPoint.zoomForSpread(located, fallback: 13),
            interactive: widget.onMapTap == null,
            onPinTap: widget.onMapTap == null ? _onPinTap : null,
          )
        : SizedBox(
            height: widget.height,
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

    if (widget.onMapTap == null) return map;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(child: map),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onMapTap,
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
