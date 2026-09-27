import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/event_join_status.dart';
import '../domain/event_participation.dart';
import '../../event/application/event_detail_provider.dart';
import '../../shell/application/feed_controller.dart';

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
    _invalidateEvent(eventId);
    return next;
  }

  Future<void> leave(String eventId) async {
    final repo = ref.read(participationRepositoryProvider);
    await repo.leave(eventId);
    state = {...state, eventId: EventJoinStatus.canJoin};
    _invalidateEvent(eventId);
  }

  Future<List<EventParticipation>> listParticipations(String eventId) {
    return ref.read(participationRepositoryProvider).listParticipations(eventId);
  }

  Future<void> updateParticipation(
    String eventId,
    String participationId, {
    required bool accept,
  }) async {
    final repo = ref.read(participationRepositoryProvider);
    await repo.updateParticipation(participationId, accept: accept);
    _invalidateEvent(eventId);
  }

  void _invalidateEvent(String eventId) {
    ref.invalidate(feedControllerProvider);
    ref.invalidate(eventDetailProvider(eventId));
  }
}

final participationControllerProvider =
    NotifierProvider<ParticipationController, Map<String, EventJoinStatus>>(
  ParticipationController.new,
);
