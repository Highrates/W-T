import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/profile_event_preview.dart';
import '../../../shared/models/user_profile.dart';
import '../../create_route/data/create_route_draft_storage.dart';
import '../../create_route/domain/create_route_step.dart';
import '../../templates/domain/route_template_summary.dart';
import '../domain/route_draft_summary.dart';

class MyPageData {
  const MyPageData({
    required this.profile,
    required this.hostingUpcoming,
    required this.hostingPast,
    required this.goingUpcoming,
    required this.goingPast,
    this.routeDraft,
    this.templates = const [],
  });

  final UserProfile profile;
  final List<ProfileEventPreview> hostingUpcoming;
  final List<ProfileEventPreview>? hostingPast;
  final List<ProfileEventPreview> goingUpcoming;
  final List<ProfileEventPreview> goingPast;
  final RouteDraftSummary? routeDraft;
  final List<RouteTemplateSummary> templates;
}

final myPageDataProvider = FutureProvider<MyPageData>((ref) async {
  final profiles = ref.read(userProfileRepositoryProvider);
  final auth = ref.read(authSessionProvider);
  final userId = ApiConfig.useApi
      ? (auth.userId ?? profiles.currentUserId)
      : profiles.currentUserId;
  final profile = await profiles.getProfile(userId);
  if (profile == null) {
    throw StateError('Current user profile not found');
  }

  RouteDraftSummary? draftSummary;
  final saved = await ref.read(createRouteDraftStorageProvider).load();
  if (saved != null) {
    final title = saved.draft.title.trim();
    draftSummary = RouteDraftSummary(
      title: title.isEmpty ? 'Событие без названия' : title,
      stepTitle: saved.step.title,
      pointCount: saved.draft.points.length,
    );
  }

  final templates = auth.isAuthenticated
      ? await ref.read(templatesRepositoryProvider).listMine()
      : const <RouteTemplateSummary>[];

  return MyPageData(
    profile: profile,
    hostingUpcoming: profile.upcomingEvents,
    hostingPast: profile.pastEvents,
    goingUpcoming: await profiles.getGoingEvents(userId),
    goingPast: await profiles.getGoingPastEvents(userId),
    routeDraft: draftSummary,
    templates: templates,
  );
});
