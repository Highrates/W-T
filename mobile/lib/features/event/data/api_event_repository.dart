import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../shared/models/event_detail_data.dart';
import '../../../shared/models/event_card_data.dart';
import '../../create_route/domain/create_route_draft.dart';
import '../../create_route/domain/create_route_source.dart';
import '../../shell/domain/feed_query.dart';
import 'event_api_mapper.dart';
import 'event_repository.dart';

class ApiEventRepository implements EventRepository {
  ApiEventRepository(this._api, this._readAuth);

  final ApiClient _api;
  final AuthSession Function() _readAuth;

  @override
  Future<List<EventCardData>> getFeed({FeedQuery? query}) async {
    final params = <String, String>{};
    if (query != null) {
      params['city_id'] = query.effectiveCityId;
      if (query.hotFilterIds.isNotEmpty) {
        params['filters'] = query.hotFilterIds.join(',');
      }
    }

    final json = await _api.getJson(
      '/feed',
      query: params,
      auth: _readAuth().isAuthenticated,
    );

    final items = json['items'];
    if (items is! List) return const [];

    return [
      for (final item in items)
        if (item is Map<String, dynamic>) eventCardFromJson(item),
    ];
  }

  @override
  Future<EventDetailData?> getDetail(String eventId) async {
    try {
      final json = await _api.getJson(
        '/occurrences/$eventId',
        auth: _readAuth().isAuthenticated,
      );
      return eventDetailFromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<String> publishFromDraft(CreateRouteDraft draft) async {
    if (!_readAuth().isAuthenticated) {
      throw ApiException('Войдите в аккаунт, чтобы опубликовать маршрут');
    }

    final body = _draftToBody(draft);
    final json = await _api.postJson('/occurrences', body: body, auth: true);
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw ApiException('Publish response missing id');
    }
    return id;
  }

  Map<String, dynamic> _draftToBody(CreateRouteDraft draft) {
    final coverUrls = draft.coverAssets
        .where((ref) => ref.startsWith('http://') || ref.startsWith('https://'))
        .toList();

    return {
      'source': _sourceName(draft.source),
      if (draft.sourceEventId != null) 'sourceOccurrenceId': draft.sourceEventId,
      'title': draft.title,
      'description': draft.description,
      'cityId': draft.cityId,
      'formatIds': draft.formatIds.toList(),
      'themeIds': draft.themeIds.toList(),
      if (draft.scheduledAt != null)
        'scheduledAt': draft.scheduledAt!.toIso8601String(),
      'hideExactTime': draft.hideExactTime,
      'joinMode': draft.joinMode.name,
      'maxParticipants': draft.isOneOnOne ? 2 : (draft.maxParticipants ?? 6),
      'isOneOnOne': draft.isOneOnOne,
      'coverUrls': coverUrls,
      'points': [
        for (var i = 0; i < draft.points.length; i++)
          {
            'title': draft.points[i].title,
            'latitude': draft.points[i].location.latitude,
            'longitude': draft.points[i].location.longitude,
            if (draft.points[i].address != null)
              'address': draft.points[i].address,
            if (draft.points[i].detail != null) 'detail': draft.points[i].detail,
            if (draft.points[i].description != null)
              'description': draft.points[i].description,
            'photoUrls': draft.points[i].photoAssets
                .where((r) => r.startsWith('http'))
                .toList(),
            'isStart': draft.points[i].isStart,
            'isFinish': draft.points[i].isFinish,
            'sortOrder': i,
          },
      ],
    };
  }

  String _sourceName(CreateRouteSource source) {
    switch (source) {
      case CreateRouteSource.fromPrevious:
        return 'fromPrevious';
      case CreateRouteSource.fromTemplate:
        return 'fromTemplate';
      case CreateRouteSource.blank:
        return 'blank';
    }
  }
}
