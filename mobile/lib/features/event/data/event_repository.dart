import '../../../shared/models/event_detail_data.dart';
import '../../../shared/models/event_card_data.dart';
import '../../create_route/domain/create_route_draft.dart';
import '../../shell/domain/feed_query.dart';

/// Источник данных ленты и детали мероприятия.
abstract interface class EventRepository {
  Future<List<EventCardData>> getFeed({FeedQuery? query});

  Future<EventDetailData?> getDetail(String eventId);

  Future<String> publishFromDraft(CreateRouteDraft draft);
}
