import '../../../shared/models/user_profile_data.dart';

abstract interface class UserProfileRepository {
  /// id авторизованного пользователя (личный профиль).
  String get currentUserId;

  UserProfileData? getProfile(String userId);
}
