import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/location_filter_mock.dart';
import '../domain/feed_query.dart';

/// Общее состояние фильтров ленты и карты.
class FeedQueryController extends Notifier<FeedQuery> {
  @override
  FeedQuery build() => FeedQuery(location: LocationFilterMock.defaultCity);

  void setLocation(LocationFilterOption location) {
    state = state.copyWith(location: location);
  }

  void toggleHotFilter(String id) {
    final next = Set<String>.from(state.hotFilterIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(hotFilterIds: next);
  }
}

final feedQueryControllerProvider =
    NotifierProvider<FeedQueryController, FeedQuery>(
  FeedQueryController.new,
);
