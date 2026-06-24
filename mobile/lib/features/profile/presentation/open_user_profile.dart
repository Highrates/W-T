import 'package:flutter/material.dart';

import '../data/mock_user_profile_repository.dart';
import 'user_profile_screen.dart';

/// Открыть публичный профиль по [userId].
void openUserProfile(BuildContext context, String userId) {
  final profile = userProfileRepository.getProfile(userId);
  if (profile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль не найден')),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => UserProfileScreen(profile: profile),
    ),
  );
}

/// Личный профиль текущего пользователя.
void openCurrentUserProfile(BuildContext context) {
  openUserProfile(context, userProfileRepository.currentUserId);
}
