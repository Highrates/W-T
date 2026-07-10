import '../../../shared/models/event_card_data.dart';
import '../data/feed_filter_mock.dart';
import '../data/location_filter_mock.dart';

/// Параметры выборки ленты и карты: город/радиус + горячие фильтры.
class FeedQuery {
  const FeedQuery({
    required this.location,
    this.hotFilterIds = const {},
  });

  final LocationFilterOption location;
  final Set<String> hotFilterIds;

  FeedQuery copyWith({
    LocationFilterOption? location,
    Set<String>? hotFilterIds,
  }) {
    return FeedQuery(
      location: location ?? this.location,
      hotFilterIds: hotFilterIds ?? this.hotFilterIds,
    );
  }

  bool get hasActiveFilters => hotFilterIds.isNotEmpty;

  /// Город события для фильтрации (радиус — вокруг дефолтного города в mock).
  String get effectiveCityId =>
      location.isRadius ? LocationFilterMock.defaultCity.id : location.id;

  bool matchesCard(EventCardData card) {
    if (!matchesLocation(card)) return false;
    return FeedHotFilterMock.matches(
      selectedIds: hotFilterIds,
      formatIds: card.formatIds,
      themeIds: card.themeIds,
    );
  }

  bool matchesLocation(EventCardData card) => card.cityId == effectiveCityId;
}
