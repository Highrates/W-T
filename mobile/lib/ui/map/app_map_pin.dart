import '../../shared/models/geo_point.dart';

/// Стиль метки на карте.
enum AppMapPinStyle {
  /// Кружок с обложкой события (таб «Карта»).
  eventPhoto,

  /// Веха маршрута: номер или фото + номер (страница event).
  routeWaypoint,

  /// Черновик точки при tap на карте (wizard).
  draftSelection,
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
    this.draggable = false,
  });

  final GeoPoint location;
  final String? id;
  final String? title;
  final AppMapPinStyle style;
  final String? imageAsset;
  final int? waypointIndex;

  /// Долгое нажатие + drag (MapKit). См. [MapObjectDragListener].
  final bool draggable;
}
