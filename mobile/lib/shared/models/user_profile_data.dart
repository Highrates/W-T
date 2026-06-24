import 'profile_event_preview.dart';

/// Публичный профиль пользователя (организатор и/или участник).
class UserProfileData {
  const UserProfileData({
    required this.id,
    required this.name,
    required this.avatarAsset,
    this.photoAssets = const [],
    this.bio,
    this.city,
    this.isVerified = false,
    this.interestTags = const [],
    this.upcomingEvents = const [],
    this.pastEvents,
  });

  final String id;
  final String name;
  final String avatarAsset;

  /// Фото в hero; если пусто — только [avatarAsset].
  final List<String> photoAssets;

  List<String> get heroPhotoAssets =>
      photoAssets.isNotEmpty ? photoAssets : [avatarAsset];

  final String? bio;
  final String? city;
  final bool isVerified;

  /// Интересы / форматы: Пешком, Пикники.
  final List<String> interestTags;

  final List<ProfileEventPreview> upcomingEvents;

  /// `null` — организатор скрыл прошлые события.
  final List<ProfileEventPreview>? pastEvents;

  bool get hasOrganizerActivity =>
      upcomingEvents.isNotEmpty || (pastEvents?.isNotEmpty ?? false);
}
