import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/profile_event_preview.dart';
import '../../../shared/models/user_profile.dart';
import '../../create_route/data/create_route_draft_storage.dart';
import '../../create_route/domain/create_route_step.dart';
import '../domain/route_draft_summary.dart';

class MyPageData {
  const MyPageData({
    required this.profile,
    required this.hostingUpcoming,
    required this.hostingPast,
    required this.goingUpcoming,
    required this.goingPast,
    this.routeDraft,
  });

  final UserProfile profile;
  final List<ProfileEventPreview> hostingUpcoming;
  final List<ProfileEventPreview>? hostingPast;
  final List<ProfileEventPreview> goingUpcoming;
  final List<ProfileEventPreview> goingPast;
  final RouteDraftSummary? routeDraft;
}

final myPageDataProvider = FutureProvider<MyPageData>((ref) async {
  final profiles = ref.read(userProfileRepositoryProvider);
  final userId = profiles.currentUserId;
  final profile = profiles.getProfile(userId);
  if (profile == null) {
    throw StateError('Current user profile not found');
  }

  RouteDraftSummary? draftSummary;
  final saved = await ref.read(createRouteDraftStorageProvider).load();
  if (saved != null) {
    final title = saved.draft.title.trim();
    draftSummary = RouteDraftSummary(
      title: title.isEmpty ? 'Маршрут без названия' : title,
      stepTitle: saved.step.title,
      pointCount: saved.draft.points.length,
    );
  }

  return MyPageData(
    profile: profile,
    hostingUpcoming: profile.upcomingEvents,
    hostingPast: profile.pastEvents,
    goingUpcoming: profiles.getGoingEvents(userId),
    goingPast: profiles.getGoingPastEvents(userId),
    routeDraft: draftSummary,
  );
});
