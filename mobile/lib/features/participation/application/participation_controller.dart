import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/event_join_status.dart';

/// Shared-состояние заявок на участие (синхронизирует ленту и event).
class ParticipationController extends Notifier<Map<String, EventJoinStatus>> {
  @override
  Map<String, EventJoinStatus> build() => const {};

  EventJoinStatus statusFor(String eventId, EventJoinStatus seed) {
    return state[eventId] ?? seed;
  }

  Future<EventJoinStatus> submitJoin(String eventId) async {
    final repo = ref.read(participationRepositoryProvider);
    final next = await repo.submitJoin(eventId);
    state = {...state, eventId: next};
    return next;
  }
}

final participationControllerProvider =
    NotifierProvider<ParticipationController, Map<String, EventJoinStatus>>(
  ParticipationController.new,
);
