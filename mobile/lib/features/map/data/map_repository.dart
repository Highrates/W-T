import '../../../shared/models/map_occurrence_pin.dart';
import '../../shell/domain/feed_query.dart';

/// Пины событий на карте.
abstract interface class MapRepository {
  Future<List<MapOccurrencePin>> getOccurrencePins({FeedQuery? query});
}
