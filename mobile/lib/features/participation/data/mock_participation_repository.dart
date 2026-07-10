import '../../../shared/models/event_join_status.dart';
import 'participation_repository.dart';

/// Мок API заявки на участие до NestJS.
class MockParticipationRepository implements ParticipationRepository {
  const MockParticipationRepository();

  @override
  Future<EventJoinStatus> submitJoin(String eventId) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return EventJoinStatus.pending;
  }
}
