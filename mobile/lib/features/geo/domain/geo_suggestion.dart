import '../../../shared/models/geo_point.dart';

/// Результат suggest / reverse geocode с бэкенда.
class GeoSuggestion {
  const GeoSuggestion({
    required this.title,
    required this.subtitle,
    required this.location,
    this.cityId,
  });

  final String title;
  final String subtitle;
  final GeoPoint location;
  final String? cityId;

  String get resolvedCityId => cityId ?? '';
}
