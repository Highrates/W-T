import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/config/api_config.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import 'open_my_profile.dart';

/// Открыть публичный профиль по [userId].
void openUserProfile(BuildContext context, String userId) {
  final container = ProviderScope.containerOf(context);
  final currentUserId = ApiConfig.useApi
      ? container.read(authSessionProvider).userId
      : container.read(userProfileRepositoryProvider).currentUserId;
  if (currentUserId != null && userId == currentUserId) {
    openMyProfile(context);
    return;
  }
  context.push(AppRoutes.profilePath(userId));
}

/// Личный профиль текущего пользователя.
void openCurrentUserProfile(BuildContext context) {
  openMyProfile(context);
}
