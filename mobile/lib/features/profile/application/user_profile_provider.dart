import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../shared/models/user_profile.dart';

final userProfileProvider =
    Provider.family<UserProfile?, String>((ref, userId) {
  return ref.read(userProfileRepositoryProvider).getProfile(userId);
});
