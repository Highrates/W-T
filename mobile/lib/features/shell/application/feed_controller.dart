import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/event_card_data.dart';
import '../../participation/application/participation_controller.dart';
import 'feed_query_controller.dart';

/// Отфильтрованная лента с актуальными статусами участия.
final feedControllerProvider =
    FutureProvider<List<EventCardData>>((ref) async {
  final query = ref.watch(feedQueryControllerProvider);
  final joinStatuses = ref.watch(participationControllerProvider);
  final events = ref.read(eventRepositoryProvider);

  final cards = await events.getFeed(query: query);

  return cards.map((card) {
    final status = joinStatuses[card.id] ?? card.joinStatus;
    return status == card.joinStatus ? card : card.copyWith(joinStatus: status);
  }).toList();
});
