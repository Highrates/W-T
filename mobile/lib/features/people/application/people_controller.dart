import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/user_profile.dart';
import '../../shell/application/feed_query_controller.dart';

final peopleListProvider = FutureProvider<List<UserProfile>>((ref) async {
  final query = ref.watch(feedQueryControllerProvider);
  return ref.read(peopleRepositoryProvider).listPeople(query: query);
});
