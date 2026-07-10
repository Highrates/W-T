import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/event_card_data.dart';
import '../../participation/application/participation_controller.dart';
import 'feed_query_controller.dart';

/// Отфильтрованная лента с актуальными статусами участия.
/// Кэшируется Riverpod до смены фильтров или join-status.
final feedControllerProvider = Provider<List<EventCardData>>((ref) {
  final query = ref.watch(feedQueryControllerProvider);
  final joinStatuses = ref.watch(participationControllerProvider);
  final events = ref.read(eventRepositoryProvider);

  return events.getFeed(query: query).map((card) {
    final status = joinStatuses[card.id] ?? card.joinStatus;
    return status == card.joinStatus ? card : card.copyWith(joinStatus: status);
  }).toList();
});
