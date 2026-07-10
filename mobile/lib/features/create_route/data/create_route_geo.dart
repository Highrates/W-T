import 'dart:math' as math;

import '../../../shared/models/geo_point.dart';

/// Mock-резолвер города по координатам (замена Геокодера на MVP).
abstract final class CreateRouteGeo {
  static const _cityAnchors = <({String id, GeoPoint center, double radiusKm})>[
    (
      id: 'sochi',
      center: GeoPoint(latitude: 43.5855, longitude: 39.7231),
      radiusKm: 80,
    ),
    (
      id: 'moscow',
      center: GeoPoint(latitude: 55.7558, longitude: 37.6173),
      radiusKm: 60,
    ),
    (
      id: 'spb',
      center: GeoPoint(latitude: 59.9343, longitude: 30.3351),
      radiusKm: 50,
    ),
    (
      id: 'kazan',
      center: GeoPoint(latitude: 55.7961, longitude: 49.1064),
      radiusKm: 40,
    ),
  ];

  /// Город карточки в ленте = город точки старта.
  static String resolveCityId(GeoPoint point) {
    var bestId = 'sochi';
    var bestDistance = double.infinity;

    for (final anchor in _cityAnchors) {
      final distance = _haversineKm(
        point.latitude,
        point.longitude,
        anchor.center.latitude,
        anchor.center.longitude,
      );
      if (distance <= anchor.radiusKm && distance < bestDistance) {
        bestDistance = distance;
        bestId = anchor.id;
      }
    }

    return bestId;
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * math.pi / 180;
}
