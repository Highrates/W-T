import '../../../shared/models/geo_point.dart';
import '../../../shared/models/map_occurrence_pin.dart';
import '../../event/data/mock_event_repository.dart';
import 'map_repository.dart';

/// Моки пинов до `GET /occurrences?bbox=…` на API.
class MockMapRepository implements MapRepository {
  const MockMapRepository();

  /// Координаты на суше (центр Сочи, парки, набережная — не в море).
  static const _centers = <String, GeoPoint>{
    'dragons': GeoPoint(latitude: 43.5782, longitude: 39.7194),
    'terrenkur': GeoPoint(latitude: 43.5708, longitude: 39.7265),
    'sunset': GeoPoint(latitude: 43.5746, longitude: 39.7248),
    'yoga-park': GeoPoint(latitude: 43.5715, longitude: 39.7312),
    'sochi-drive': GeoPoint(latitude: 43.5924, longitude: 39.7168),
    'banya-chill': GeoPoint(latitude: 43.5768, longitude: 39.7156),
    'text-tea-walk': GeoPoint(latitude: 43.5734, longitude: 39.7281),
  };

  @override
  List<MapOccurrencePin> getOccurrencePins() {
    return [
      for (final card in eventRepository.getFeed())
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

const mapRepository = MockMapRepository();
