import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit_lite/image.dart' as mapkit_image;
import 'package:yandex_maps_mapkit_lite/mapkit.dart';
// ignore: implementation_imports
import 'package:yandex_maps_mapkit_lite/src/bindings/view/platform_view_type.dart';
// ignore: implementation_imports
import 'package:yandex_maps_mapkit_lite/src/bindings/widgets/yandex_map.dart';

import '../../core/map/mapkit_bootstrap.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/geo_point.dart';
import 'app_map_pin.dart';
import 'map_marker_renderer.dart';
import 'map_unavailable_placeholder.dart';

/// Обёртка Yandex MapKit: камера, метки, маршрут.
class AppYandexMap extends StatefulWidget {
  const AppYandexMap({
    super.key,
    required this.pins,
    this.initialCenter,
    this.initialZoom = 12,
    this.interactive = true,
    this.height,
    this.borderRadius = 0,
    this.onPinTap,
    this.showRoutePolyline = false,
    this.largeRouteMarkers = false,
  });

  final List<AppMapPin> pins;
  final GeoPoint? initialCenter;
  final double initialZoom;
  final bool interactive;
  final double? height;
  final double borderRadius;
  final ValueChanged<AppMapPin>? onPinTap;
  final bool showRoutePolyline;
  final bool largeRouteMarkers;

  @override
  State<AppYandexMap> createState() => _AppYandexMapState();
}

class _AppYandexMapState extends State<AppYandexMap> {
  MapWindow? _mapWindow;
  final List<PlacemarkMapObject> _placemarks = [];
  final List<MapObjectTapListener> _tapListeners = [];
  PolylineMapObject? _routePolyline;

  @override
  void didUpdateWidget(covariant AppYandexMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapWindow != null &&
        (oldWidget.pins != widget.pins ||
            oldWidget.initialCenter != widget.initialCenter ||
            oldWidget.initialZoom != widget.initialZoom ||
            oldWidget.showRoutePolyline != widget.showRoutePolyline)) {
      _applyCameraAndPins(_mapWindow!);
    }
  }

  void _onMapCreated(MapWindow mapWindow) {
    _mapWindow = mapWindow;
    _applyCameraAndPins(mapWindow);
  }

  void _applyCameraAndPins(MapWindow mapWindow) {
    final map = mapWindow.map;
    final pins = widget.pins;

    _clearMapObjects(map);

    final center = widget.initialCenter ??
        GeoPoint.centroid(pins.map((p) => p.location)) ??
        const GeoPoint(latitude: 43.5855, longitude: 39.7231);

    final zoom = pins.length > 1
        ? GeoPoint.zoomForSpread(pins.map((p) => p.location))
        : widget.initialZoom;

    map.move(
      CameraPosition(
        Point(latitude: center.latitude, longitude: center.longitude),
        zoom: zoom,
        azimuth: 0,
        tilt: 0,
      ),
    );

    if (widget.showRoutePolyline && pins.length >= 2) {
      final polyline = map.mapObjects.addPolyline();
      polyline.geometry = Polyline([
        for (final pin in pins)
          Point(
            latitude: pin.location.latitude,
            longitude: pin.location.longitude,
          ),
      ]);
      polyline.setStrokeColor(AppPalette.blue.withValues(alpha: 0.85));
      polyline.style = const LineStyle(
        strokeWidth: 4,
        turnRadius: 12,
      );
      _routePolyline = polyline;
    }

    for (final pin in pins) {
      final placemark = map.mapObjects.addPlacemark()
        ..geometry = Point(
          latitude: pin.location.latitude,
          longitude: pin.location.longitude,
        );

      final isEvent = pin.style == AppMapPinStyle.eventPhoto;
      final markerSize = isEvent
          ? 128.0
          : (widget.largeRouteMarkers ? 132.0 : 96.0);
      placemark.setIconWithStyle(
        mapkit_image.ImageProvider(() => _markerImageFor(pin, markerSize)),
        IconStyle(
          anchor: MapMarkerRenderer.centerAnchor(),
          scale: MapMarkerRenderer.markerScale(
            markerSize,
            isEventPhoto: isEvent,
            largeRoute: widget.largeRouteMarkers && !isEvent,
          ),
        ),
      );

      _placemarks.add(placemark);

      if (widget.onPinTap != null) {
        final listener = _PinTapListener(onTap: () => widget.onPinTap!(pin));
        _tapListeners.add(listener);
        placemark.addTapListener(listener);
      }
    }

    map.set2DMode(true);
    map.rotateGesturesEnabled = widget.interactive;
    map.scrollGesturesEnabled = widget.interactive;
    map.zoomGesturesEnabled = widget.interactive;
    map.tiltGesturesEnabled = false;
  }

  void _clearMapObjects(Map map) {
    for (final placemark in _placemarks) {
      map.mapObjects.remove(placemark);
    }
    _placemarks.clear();
    _tapListeners.clear();

    if (_routePolyline != null) {
      map.mapObjects.remove(_routePolyline!);
      _routePolyline = null;
    }
  }

  @override
  void dispose() {
    final window = _mapWindow;
    if (window != null) {
      _clearMapObjects(window.map);
      _mapWindow = null;
    }
    super.dispose();
  }

  Future<ui.Image> _markerImageFor(AppMapPin pin, double markerSize) {
    return switch (pin.style) {
      AppMapPinStyle.eventPhoto => MapMarkerRenderer.eventPhotoMarker(
          assetPath: pin.imageAsset ?? 'assets/images/cards/01.jpg',
          size: markerSize,
        ),
      AppMapPinStyle.routeWaypoint => MapMarkerRenderer.routeWaypointMarker(
          index: pin.waypointIndex ?? 1,
          photoAsset: pin.imageAsset,
          size: markerSize,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!MapKitBootstrap.isReady) {
      return MapUnavailablePlaceholder(
        height: widget.height,
        borderRadius: widget.borderRadius,
        hint: 'flutter run --dart-define-from-file=dart_defines.json',
      );
    }

    final map = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: YandexMap(
        platformViewType: !kIsWeb && Platform.isAndroid
            ? PlatformViewType.Hybrid
            : PlatformViewType.Compat,
        onMapCreated: _onMapCreated,
      ),
    );

    if (widget.height != null) {
      return SizedBox(height: widget.height, width: double.infinity, child: map);
    }

    return map;
  }
}

final class _PinTapListener implements MapObjectTapListener {
  _PinTapListener({required this.onTap});

  final VoidCallback onTap;

  @override
  bool onMapObjectTap(MapObject mapObject, Point point) {
    onTap();
    return true;
  }
}
