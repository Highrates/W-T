import '../../../shared/models/geo_point.dart';
import 'create_route_geo.dart';

/// Результат mock-поиска мест (Геосаджест через бэкенд — позже).
class CreateRoutePlaceSuggestion {
  const CreateRoutePlaceSuggestion({
    required this.title,
    required this.subtitle,
    required this.location,
    this.cityId,
  });

  final String title;
  final String subtitle;
  final GeoPoint location;
  final String? cityId;

  String get resolvedCityId => cityId ?? CreateRouteGeo.resolveCityId(location);
}

/// Mock Геосаджест для шага «Точки маршрута».
abstract final class CreateRoutePlaceSearchMock {
  static const _catalog = [
    CreateRoutePlaceSuggestion(
      title: 'Парк Ривьера',
      subtitle: 'Сочи, Курортный проспект',
      location: GeoPoint(latitude: 43.5731, longitude: 39.7392),
      cityId: 'sochi',
    ),
    CreateRoutePlaceSuggestion(
      title: 'Смотровая площадка Ахун',
      subtitle: 'Сочи, гора Ахун',
      location: GeoPoint(latitude: 43.5680, longitude: 39.7450),
      cityId: 'sochi',
    ),
    CreateRoutePlaceSuggestion(
      title: 'Набережная Сочи',
      subtitle: 'Сочи, центр',
      location: GeoPoint(latitude: 43.5645, longitude: 39.7485),
      cityId: 'sochi',
    ),
    CreateRoutePlaceSuggestion(
      title: 'Фетучини',
      subtitle: 'Сочи, ресторан, Курортный проспект',
      location: GeoPoint(latitude: 43.5778, longitude: 39.7264),
      cityId: 'sochi',
    ),
    CreateRoutePlaceSuggestion(
      title: 'Парк Горького',
      subtitle: 'Москва, центр',
      location: GeoPoint(latitude: 55.7310, longitude: 37.6014),
      cityId: 'moscow',
    ),
    CreateRoutePlaceSuggestion(
      title: 'Летний сад',
      subtitle: 'Санкт-Петербург',
      location: GeoPoint(latitude: 59.9444, longitude: 30.3365),
      cityId: 'spb',
    ),
    CreateRoutePlaceSuggestion(
      title: 'Казанский Кремль',
      subtitle: 'Казань',
      location: GeoPoint(latitude: 55.7985, longitude: 49.1053),
      cityId: 'kazan',
    ),
  ];

  static List<CreateRoutePlaceSuggestion> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    return _catalog
        .where(
          (place) =>
              place.title.toLowerCase().contains(normalized) ||
              place.subtitle.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }
}
