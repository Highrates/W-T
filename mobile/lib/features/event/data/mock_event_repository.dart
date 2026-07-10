import '../../../shared/models/event_detail_data.dart';
import '../../../shared/models/event_card_data.dart';
import '../../../shared/models/event_route_point.dart';
import '../../cards/data/cards_feed_mock.dart';
import '../../create_route/data/create_route_publisher.dart';
import '../../create_route/domain/create_route_draft.dart';
import '../../shell/domain/feed_query.dart';
import 'event_repository.dart';
import 'event_route_points_mock.dart';

/// Мок-реализация [EventRepository] до подключения API.
class MockEventRepository implements EventRepository {
  MockEventRepository();

  final List<EventCardData> _publishedEvents = [];
  final Map<String, List<EventRoutePoint>> _publishedRoutePoints = {};

  @override
  List<EventCardData> getFeed({FeedQuery? query}) {
    final all = [...CardsFeedMock.feed, ..._publishedEvents];
    if (query == null) return all;
    return all.where(query.matchesCard).toList();
  }

  @override
  EventDetailData? getDetail(String eventId) {
    for (final card in _publishedEvents) {
      if (card.id == eventId) {
        return EventDetailData(
          event: card,
          routePoints: _publishedRoutePoints[eventId] ?? const [],
        );
      }
    }

    for (final card in CardsFeedMock.feed) {
      if (card.id == eventId) {
        return EventDetailData(
          event: card,
          routePoints: EventRoutePointsMock.forEvent(card.id),
        );
      }
    }
    return null;
  }

  @override
  String publishFromDraft(CreateRouteDraft draft) {
    final eventId = CreateRoutePublisher.generateEventId();
    final event = CreateRoutePublisher.toEventCard(
      draft: draft,
      eventId: eventId,
    );
    final points = CreateRoutePublisher.toRoutePoints(draft);

    _publishedEvents.insert(0, event);
    _publishedRoutePoints[eventId] = points;
    return eventId;
  }
}
