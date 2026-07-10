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
    this.onMapTap,
    this.onPinDragEnd,
    this.draftPin,
    this.showRoutePolyline = false,
    this.largeRouteMarkers = false,
    this.preserveCameraOnUpdate = false,
  });

  final List<AppMapPin> pins;
  final GeoPoint? initialCenter;
  final double initialZoom;
  final bool interactive;
  final double? height;
  final double borderRadius;
  final ValueChanged<AppMapPin>? onPinTap;
  final ValueChanged<GeoPoint>? onMapTap;
  final void Function(AppMapPin pin, GeoPoint location)? onPinDragEnd;
  final GeoPoint? draftPin;
  final bool showRoutePolyline;
  final bool largeRouteMarkers;

  /// Не сбрасывать камеру при обновлении пинов (wizard drag / polyline).
  final bool preserveCameraOnUpdate;

  @override
  State<AppYandexMap> createState() => _AppYandexMapState();
}

class _AppYandexMapState extends State<AppYandexMap> {
  MapWindow? _mapWindow;
  final List<_PlacemarkEntry> _placemarkEntries = [];
  MapInputListener? _inputListener;
  PolylineMapObject? _routePolyline;
  var _didFitCamera = false;

  @override
  void didUpdateWidget(covariant AppYandexMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapWindow != null &&
        (oldWidget.pins != widget.pins ||
            oldWidget.draftPin != widget.draftPin ||
            oldWidget.initialCenter != widget.initialCenter ||
            oldWidget.initialZoom != widget.initialZoom ||
            oldWidget.showRoutePolyline != widget.showRoutePolyline ||
            oldWidget.onMapTap != widget.onMapTap ||
            oldWidget.onPinDragEnd != widget.onPinDragEnd ||
            oldWidget.preserveCameraOnUpdate != widget.preserveCameraOnUpdate)) {
      _applyCameraAndPins(_mapWindow!);
    }
  }

  void _onMapCreated(MapWindow mapWindow) {
    _mapWindow = mapWindow;
    _didFitCamera = false;
    _applyCameraAndPins(mapWindow);
  }

  void _applyCameraAndPins(MapWindow mapWindow) {
    final map = mapWindow.map;
    final pins = widget.pins;
    final allPins = [
      ...pins,
      if (widget.draftPin != null)
        AppMapPin(
          id: '__draft__',
          location: widget.draftPin!,
          style: AppMapPinStyle.draftSelection,
          draggable: widget.onPinDragEnd != null,
        ),
    ];

    _clearMapObjects(map);

    final shouldMoveCamera =
        !widget.preserveCameraOnUpdate || !_didFitCamera;

    if (shouldMoveCamera) {
      final center = widget.initialCenter ??
          GeoPoint.centroid(allPins.map((p) => p.location)) ??
          const GeoPoint(latitude: 43.5855, longitude: 39.7231);

      final zoom = allPins.length > 1
          ? GeoPoint.zoomForSpread(allPins.map((p) => p.location))
          : widget.initialZoom;

      map.move(
        CameraPosition(
          Point(latitude: center.latitude, longitude: center.longitude),
          zoom: zoom,
          azimuth: 0,
          tilt: 0,
        ),
      );
      _didFitCamera = true;
    }

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

    for (final pin in allPins) {
      final placemark = map.mapObjects.addPlacemark()
        ..geometry = Point(
          latitude: pin.location.latitude,
          longitude: pin.location.longitude,
        );

      final isEvent = pin.style == AppMapPinStyle.eventPhoto;
      final isDraft = pin.style == AppMapPinStyle.draftSelection;
      final markerSize = isEvent
          ? 128.0
          : (isDraft
              ? 56.0
              : (widget.largeRouteMarkers ? 132.0 : 96.0));
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

      final entry = _PlacemarkEntry(placemark: placemark, pin: pin);

      if (widget.onPinTap != null) {
        final listener = _PinTapListener(onTap: () => widget.onPinTap!(pin));
        entry.tapListener = listener;
        placemark.addTapListener(listener);
      }

      final canDrag = pin.draggable && widget.onPinDragEnd != null;
      if (canDrag) {
        placemark.draggable = true;
        final dragListener = _PinDragListener(
          onEnd: (point) => widget.onPinDragEnd!(
            pin,
            GeoPoint(latitude: point.latitude, longitude: point.longitude),
          ),
        );
        entry.dragListener = dragListener;
        placemark.setDragListener(dragListener);
      }

      _placemarkEntries.add(entry);
    }

    map.set2DMode(true);
    map.rotateGesturesEnabled = widget.interactive;
    map.scrollGesturesEnabled = widget.interactive;
    map.zoomGesturesEnabled = widget.interactive;
    map.tiltGesturesEnabled = false;

    if (widget.onMapTap != null) {
      final listener = _MapTapInputListener(
        onTap: (point) => widget.onMapTap!(
          GeoPoint(latitude: point.latitude, longitude: point.longitude),
        ),
      );
      _inputListener = listener;
      map.addInputListener(listener);
    }
  }

  void _clearMapObjects(Map map) {
    if (_inputListener != null) {
      map.removeInputListener(_inputListener!);
      _inputListener = null;
    }

    for (final entry in _placemarkEntries) {
      entry.placemark.setDragListener(null);
      if (entry.tapListener != null) {
        entry.placemark.removeTapListener(entry.tapListener!);
      }
      map.mapObjects.remove(entry.placemark);
    }
    _placemarkEntries.clear();

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
      AppMapPinStyle.draftSelection => MapMarkerRenderer.draftSelectionMarker(
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

class _PlacemarkEntry {
  _PlacemarkEntry({required this.placemark, required this.pin});

  final PlacemarkMapObject placemark;
  final AppMapPin pin;
  MapObjectTapListener? tapListener;
  MapObjectDragListener? dragListener;
}

final class _MapTapInputListener implements MapInputListener {
  _MapTapInputListener({required this.onTap});

  final void Function(Point point) onTap;

  @override
  void onMapTap(Map map, Point point) => onTap(point);

  @override
  void onMapLongTap(Map map, Point point) {}
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

final class _PinDragListener implements MapObjectDragListener {
  _PinDragListener({required this.onEnd});

  final void Function(Point point) onEnd;
  Point? _lastPoint;

  @override
  void onMapObjectDragStart(MapObject mapObject) {}

  @override
  void onMapObjectDrag(MapObject mapObject, Point point) {
    _lastPoint = point;
  }

  @override
  void onMapObjectDragEnd(MapObject mapObject) {
    final point = _lastPoint;
    if (point != null) {
      onEnd(point);
    }
    _lastPoint = null;
  }
}
