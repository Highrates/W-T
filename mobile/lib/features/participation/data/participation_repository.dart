import '../../../shared/models/event_join_status.dart';
import '../domain/event_participation.dart';

/// Заявки на участие в событиях.
abstract interface class ParticipationRepository {
  Future<EventJoinStatus> submitJoin(String eventId);

  Future<void> leave(String eventId);

  Future<List<EventParticipation>> listParticipations(String eventId);

  Future<void> updateParticipation(String participationId, {required bool accept});
}
