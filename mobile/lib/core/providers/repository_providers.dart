import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../config/api_config.dart';
import '../providers/auth_providers.dart';
import '../../features/chat/data/api_chat_repository.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/data/mock_chat_repository.dart';
import '../../features/auth/data/api_auth_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/event/data/api_event_repository.dart';
import '../../features/event/data/event_repository.dart';
import '../../features/event/data/mock_event_repository.dart';
import '../../features/map/data/api_map_repository.dart';
import '../../features/map/data/map_repository.dart';
import '../../features/map/data/mock_map_repository.dart';
import '../../features/participation/data/api_participation_repository.dart';
import '../../features/participation/data/mock_participation_repository.dart';
import '../../features/participation/data/participation_repository.dart';
import '../../features/reports/data/api_reports_repository.dart';
import '../../features/reports/data/mock_reports_repository.dart';
import '../../features/reports/data/reports_repository.dart';
import '../../features/templates/data/api_templates_repository.dart';
import '../../features/templates/data/mock_templates_repository.dart';
import '../../features/templates/data/templates_repository.dart';
import '../../features/people/data/api_people_repository.dart';
import '../../features/people/data/mock_people_repository.dart';
import '../../features/people/data/people_repository.dart';
import '../../features/profile/data/api_user_profile_repository.dart';
import '../../features/profile/data/mock_user_profile_repository.dart';
import '../../features/profile/data/user_profile_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(apiClientProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  if (!ApiConfig.useApi) {
    return MockEventRepository();
  }
  return ApiEventRepository(
    ref.watch(apiClientProvider),
    () => ref.read(authSessionProvider),
  );
});

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final events = ref.watch(eventRepositoryProvider);
  if (!ApiConfig.useApi) {
    return MockMapRepository(events);
  }
  return ApiMapRepository(
    ref.watch(apiClientProvider),
    () => ref.read(authSessionProvider),
  );
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  if (!ApiConfig.useApi) {
    return const MockUserProfileRepository();
  }
  return ApiUserProfileRepository(
    ref.watch(apiClientProvider),
    () => ref.read(authSessionProvider),
  );
});

final participationRepositoryProvider = Provider<ParticipationRepository>((ref) {
  if (!ApiConfig.useApi) {
    return const MockParticipationRepository();
  }
  return ApiParticipationRepository(
    ref.watch(apiClientProvider),
    () => ref.read(authSessionProvider),
  );
});

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  if (!ApiConfig.useApi) {
    return MockPeopleRepository(ref.watch(userProfileRepositoryProvider));
  }
  return ApiPeopleRepository(ref.watch(apiClientProvider));
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  if (!ApiConfig.useApi) {
    return const MockReportsRepository();
  }
  return ApiReportsRepository(
    ref.watch(apiClientProvider),
    () => ref.read(authSessionProvider),
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (!ApiConfig.useApi) {
    return const MockChatRepository();
  }
  return ApiChatRepository(
    ref.watch(apiClientProvider),
    () => ref.read(authSessionProvider),
  );
});

final templatesRepositoryProvider = Provider<TemplatesRepository>((ref) {
  if (!ApiConfig.useApi) {
    return const MockTemplatesRepository();
  }
  return ApiTemplatesRepository(
    ref.watch(apiClientProvider),
    () => ref.read(authSessionProvider),
  );
});
