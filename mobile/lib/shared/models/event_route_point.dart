import 'geo_point.dart';

/// Точка маршрута на странице мероприятия.
class EventRoutePoint {
  const EventRoutePoint({
    required this.title,
    required this.location,
    this.address,
    this.detail,
    this.description,
    this.photoAssets = const [],
    this.poiId,
  });

  final String title;

  /// Координаты из API (PostGIS / геокодер на бэкенде).
  final GeoPoint location;

  /// Человекочитаемый адрес (ответ Геокодера).
  final String? address;
  final String? detail;

  /// Подробное описание локации (в развёрнутом блоке).
  final String? description;
  final List<String> photoAssets;

  /// ID организации Яндекса, если точка привязана к POI.
  final String? poiId;
}
