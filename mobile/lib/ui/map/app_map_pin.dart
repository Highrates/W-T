import '../../shared/models/geo_point.dart';

/// Стиль метки на карте.
enum AppMapPinStyle {
  /// Кружок с обложкой события (таб «Карта»).
  eventPhoto,

  /// Веха маршрута: номер или фото + номер (страница event).
  routeWaypoint,
}

/// Пин на карте Walk&Talk.
class AppMapPin {
  const AppMapPin({
    required this.location,
    this.id,
    this.title,
    this.style = AppMapPinStyle.eventPhoto,
    this.imageAsset,
    this.waypointIndex,
  });

  final GeoPoint location;
  final String? id;
  final String? title;
  final AppMapPinStyle style;
  final String? imageAsset;
  final int? waypointIndex;
}
