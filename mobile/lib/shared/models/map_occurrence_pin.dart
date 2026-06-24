import 'geo_point.dart';

/// Пин события на карте (таб «Карта»).
class MapOccurrencePin {
  const MapOccurrencePin({
    required this.occurrenceId,
    required this.title,
    required this.location,
    required this.coverAsset,
    this.subtitle,
  });

  final String occurrenceId;
  final String title;
  final GeoPoint location;

  /// Первая обложка события — для круглой метки на карте.
  final String coverAsset;
  final String? subtitle;
}
