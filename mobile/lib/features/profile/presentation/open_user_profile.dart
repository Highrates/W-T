import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/providers/repository_providers.dart';
import 'open_my_profile.dart';

/// Открыть публичный профиль по [userId].
void openUserProfile(BuildContext context, String userId) {
  final container = ProviderScope.containerOf(context);
  final profiles = container.read(userProfileRepositoryProvider);
  if (userId == profiles.currentUserId) {
    openMyProfile(context);
    return;
  }
  context.push(AppRoutes.profilePath(userId));
}

/// Личный профиль текущего пользователя.
void openCurrentUserProfile(BuildContext context) {
  openMyProfile(context);
}
