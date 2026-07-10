import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/event_detail_data.dart';
import '../../participation/application/participation_controller.dart';

/// Деталь события с актуальным join-status.
final eventDetailProvider = Provider.family<EventDetailData?, String>((ref, id) {
  final detail = ref.read(eventRepositoryProvider).getDetail(id);
  if (detail == null) return null;

  final joinStatuses = ref.watch(participationControllerProvider);
  final status = joinStatuses[id] ?? detail.event.joinStatus;
  if (status == detail.event.joinStatus) return detail;

  return EventDetailData(
    event: detail.event.copyWith(joinStatus: status),
    routePoints: detail.routePoints,
  );
});
