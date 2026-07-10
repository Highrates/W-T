import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/map_occurrence_pin.dart';
import 'feed_query_controller.dart';

/// Пины карты с учётом текущих фильтров.
final mapControllerProvider = Provider<List<MapOccurrencePin>>((ref) {
  final query = ref.watch(feedQueryControllerProvider);
  final mapRepo = ref.read(mapRepositoryProvider);
  return mapRepo.getOccurrencePins(query: query);
});
