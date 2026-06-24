import '../../../shared/models/map_occurrence_pin.dart';

/// Пины событий на карте.
abstract class MapRepository {
  List<MapOccurrencePin> getOccurrencePins();
}
