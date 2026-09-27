import '../../../shared/models/geo_point.dart';
import '../../../shared/models/map_occurrence_pin.dart';
import '../../event/data/event_repository.dart';
import '../../shell/domain/feed_query.dart';
import 'map_repository.dart';

/// Моки пинов до API.
class MockMapRepository implements MapRepository {
  MockMapRepository(this._events);

  final EventRepository _events;

  static const _centers = <String, GeoPoint>{
    'dragons': GeoPoint(latitude: 43.5782, longitude: 39.7194),
    'terrenkur': GeoPoint(latitude: 43.5708, longitude: 39.7265),
    'sunset': GeoPoint(latitude: 43.5746, longitude: 39.7248),
    'yoga-park': GeoPoint(latitude: 43.5715, longitude: 39.7312),
    'sochi-drive': GeoPoint(latitude: 43.5924, longitude: 39.7168),
    'banya-chill': GeoPoint(latitude: 43.5768, longitude: 39.7156),
    'beer-bar': GeoPoint(latitude: 43.5801, longitude: 39.7210),
    'astrakhan-fishing': GeoPoint(latitude: 46.3512, longitude: 48.0524),
    'astrakhan-embankment': GeoPoint(latitude: 46.3491, longitude: 48.0398),
    'pool-krasnaya-polyana': GeoPoint(latitude: 43.6789, longitude: 40.2045),
    'text-tea-walk': GeoPoint(latitude: 43.5734, longitude: 39.7281),
  };

  @override
  Future<List<MapOccurrencePin>> getOccurrencePins({FeedQuery? query}) async {
    final feed = await _events.getFeed(query: query);
    return [
      for (final card in feed)
        if (_centers[card.id] != null)
          MapOccurrencePin(
            occurrenceId: card.id,
            title: card.title,
            location: _centers[card.id]!,
            coverAsset: card.primaryCoverAsset ?? card.organizerAvatarAsset,
            subtitle: card.whenLabel,
          ),
    ];
  }
}
