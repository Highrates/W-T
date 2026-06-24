import '../../../shared/models/event_detail_data.dart';
import '../../../shared/models/walk_card_data.dart';
import '../../cards/data/cards_feed_mock.dart';
import 'event_repository.dart';
import 'event_route_points_mock.dart';

/// Мок-реализация [EventRepository] до подключения API.
class MockEventRepository implements EventRepository {
  const MockEventRepository();

  @override
  List<WalkCardData> getFeed() => CardsFeedMock.feed;

  @override
  EventDetailData? getDetail(String eventId) {
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
}

/// Глобальный инстанс до внедрения DI / state management.
const eventRepository = MockEventRepository();
