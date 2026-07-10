import 'event_route_point.dart';
import 'event_card_data.dart';

/// Данные экрана мероприятия (карточка ленты + детали).
class EventDetailData {
  const EventDetailData({
    required this.event,
    required this.routePoints,
  });

  final EventCardData event;
  final List<EventRoutePoint> routePoints;
}
