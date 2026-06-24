import 'dart:math' as math;

/// Географическая точка (WGS84). Источник истины — API / PostGIS.
class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  /// Центр набора точек или `null`, если список пуст.
  static GeoPoint? centroid(Iterable<GeoPoint> points) {
    final list = points.toList(growable: false);
    if (list.isEmpty) return null;

    var lat = 0.0;
    var lon = 0.0;
    for (final p in list) {
      lat += p.latitude;
      lon += p.longitude;
    }
    return GeoPoint(
      latitude: lat / list.length,
      longitude: lon / list.length,
    );
  }

  /// Подбор zoom по разбросу точек (эвристика для превью карты).
  static double zoomForSpread(Iterable<GeoPoint> points, {double fallback = 12}) {
    final list = points.toList(growable: false);
    if (list.length < 2) return fallback;

    var minLat = list.first.latitude;
    var maxLat = minLat;
    var minLon = list.first.longitude;
    var maxLon = minLon;

    for (final p in list) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLon = math.min(minLon, p.longitude);
      maxLon = math.max(maxLon, p.longitude);
    }

    final span = math.max(maxLat - minLat, maxLon - minLon);
    if (span > 0.5) return 10;
    if (span > 0.15) return 11;
    if (span > 0.05) return 12;
    if (span > 0.02) return 13;
    return 14;
  }
}
