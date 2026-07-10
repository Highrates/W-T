import '../../../shared/models/event_join_status.dart';

/// Заявки на участие в событиях.
abstract interface class ParticipationRepository {
  Future<EventJoinStatus> submitJoin(String eventId);
}
