import '../../../core/api/api_client.dart';
import '../../../shared/models/user_profile.dart';
import '../../event/data/event_api_mapper.dart';
import '../../shell/data/feed_filter_mock.dart';
import '../../shell/domain/feed_query.dart';
import 'people_repository.dart';

class ApiPeopleRepository implements PeopleRepository {
  ApiPeopleRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<UserProfile>> listPeople({FeedQuery? query}) async {
    final params = <String, String>{};
    if (query != null) {
      params['city_id'] = query.effectiveCityId;

      final interests = query.hotFilterIds
          .where(FeedHotFilterMock.isThemeId)
          .followedBy(
            query.hotFilterIds.where(FeedHotFilterMock.isFormatId),
          )
          .toList();

      if (interests.isNotEmpty) {
        params['interests'] = interests.join(',');
      }
    }

    final json = await _api.getJson('/people', query: params);
    final items = json['items'];
    if (items is! List) return const [];

    return [
      for (final item in items)
        if (item is Map<String, dynamic>) peopleItemToProfile(item),
    ];
  }
}

extension _IterableFollowedBy<E> on Iterable<E> {
  Iterable<E> followedBy(Iterable<E> other) sync* {
    yield* this;
    yield* other;
  }
}
