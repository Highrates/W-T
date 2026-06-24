import '../../../shared/models/event_detail_data.dart';
import '../../../shared/models/walk_card_data.dart';

/// Источник данных ленты и детали мероприятия.
abstract class EventRepository {
  List<WalkCardData> getFeed();

  EventDetailData? getDetail(String eventId);
}
