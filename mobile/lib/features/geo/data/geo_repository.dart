import '../../../shared/models/geo_point.dart';
import '../../create_route/data/create_route_geo.dart';
import '../../create_route/data/create_route_place_search_mock.dart';
import '../domain/geo_suggestion.dart';
import 'geo_api_client.dart';

abstract interface class GeoRepository {
  Future<List<GeoSuggestion>> suggest(String query, {GeoPoint? bias});

  Future<GeoSuggestion> reverseGeocode(GeoPoint point);
}

/// Remote API с fallback на mock при недоступности бэкенда.
class GeoRepositoryImpl implements GeoRepository {
  GeoRepositoryImpl(this._client);

  final GeoApiClient _client;

  @override
  Future<List<GeoSuggestion>> suggest(
    String query, {
    GeoPoint? bias,
  }) async {
    try {
      return await _client.suggest(query, bias: bias);
    } on GeoApiException {
      return _mockSuggest(query);
    } catch (_) {
      return _mockSuggest(query);
    }
  }

  @override
  Future<GeoSuggestion> reverseGeocode(GeoPoint point) async {
    try {
      return await _client.reverseGeocode(point);
    } on GeoApiException {
      return _mockReverse(point);
    } catch (_) {
      return _mockReverse(point);
    }
  }

  List<GeoSuggestion> _mockSuggest(String query) {
    return CreateRoutePlaceSearchMock.search(query)
        .map(
          (item) => GeoSuggestion(
            title: item.title,
            subtitle: item.subtitle,
            location: item.location,
            cityId: item.resolvedCityId,
          ),
        )
        .toList(growable: false);
  }

  GeoSuggestion _mockReverse(GeoPoint point) {
    final cityId = CreateRouteGeo.resolveCityId(point);
    return GeoSuggestion(
      title: 'Выбранная точка',
      subtitle: 'Координаты ${point.latitude.toStringAsFixed(4)}, '
          '${point.longitude.toStringAsFixed(4)}',
      location: point,
      cityId: cityId,
    );
  }
}
