import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_session.dart';
import '../../../shared/models/map_occurrence_pin.dart';
import '../../event/data/event_api_mapper.dart';
import '../../shell/domain/feed_query.dart';
import 'map_repository.dart';

class ApiMapRepository implements MapRepository {
  ApiMapRepository(this._api, this._readAuth);

  final ApiClient _api;
  final AuthSession Function() _readAuth;

  @override
  Future<List<MapOccurrencePin>> getOccurrencePins({FeedQuery? query}) async {
    final params = <String, String>{};
    if (query != null) {
      params['city_id'] = query.effectiveCityId;
      if (query.hotFilterIds.isNotEmpty) {
        params['filters'] = query.hotFilterIds.join(',');
      }
    }

    final json = await _api.getJson(
      '/occurrences/map',
      query: params,
      auth: _readAuth().isAuthenticated,
    );

    final pins = json['pins'];
    if (pins is! List) return const [];

    return [
      for (final item in pins)
        if (item is Map<String, dynamic>) mapPinFromJson(item),
    ];
  }
}
