import '../../../shared/models/event_join_status.dart';
import '../domain/event_participation.dart';
import 'participation_repository.dart';

/// Мок API заявки на участие до NestJS.
class MockParticipationRepository implements ParticipationRepository {
  const MockParticipationRepository();

  @override
  Future<EventJoinStatus> submitJoin(String eventId) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return EventJoinStatus.pending;
  }

  @override
  Future<void> leave(String eventId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<List<EventParticipation>> listParticipations(String eventId) async {
    return const [];
  }

  @override
  Future<void> updateParticipation(
    String participationId, {
    required bool accept,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
