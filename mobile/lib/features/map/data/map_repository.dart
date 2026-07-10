import '../../../shared/models/map_occurrence_pin.dart';
import '../../shell/domain/feed_query.dart';

/// Пины событий на карте.
abstract interface class MapRepository {
  List<MapOccurrencePin> getOccurrencePins({FeedQuery? query});
}
