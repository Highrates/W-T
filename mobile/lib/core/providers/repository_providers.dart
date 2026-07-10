import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/event/data/event_repository.dart';
import '../../features/event/data/mock_event_repository.dart';
import '../../features/map/data/map_repository.dart';
import '../../features/map/data/mock_map_repository.dart';
import '../../features/participation/data/mock_participation_repository.dart';
import '../../features/participation/data/participation_repository.dart';
import '../../features/profile/data/mock_user_profile_repository.dart';
import '../../features/profile/data/user_profile_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => MockEventRepository(),
);

final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => MockMapRepository(ref.watch(eventRepositoryProvider)),
);

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => MockUserProfileRepository(),
);

final participationRepositoryProvider = Provider<ParticipationRepository>(
  (ref) => const MockParticipationRepository(),
);
