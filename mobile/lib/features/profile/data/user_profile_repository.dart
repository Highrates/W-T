import '../../../shared/models/profile_event_preview.dart';
import '../../../shared/models/user_profile.dart';

abstract interface class UserProfileRepository {
  String get currentUserId;

  Future<UserProfile?> getProfile(String userId);

  Future<List<ProfileEventPreview>> getGoingEvents(String userId);

  Future<List<ProfileEventPreview>> getGoingPastEvents(String userId);

  Future<String?> updateAvatarUrl(String avatarUrl);
}
