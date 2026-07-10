import '../../../shared/models/profile_event_preview.dart';
import '../../../shared/models/user_profile.dart';

abstract interface class UserProfileRepository {
  /// id авторизованного пользователя (личный профиль).
  String get currentUserId;

  UserProfile? getProfile(String userId);

  /// События, куда пользователь идёт как участник.
  List<ProfileEventPreview> getGoingEvents(String userId);

  /// Прошедшие события-участие.
  List<ProfileEventPreview> getGoingPastEvents(String userId);
}
