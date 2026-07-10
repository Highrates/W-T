import 'profile_event_preview.dart';

/// Профиль пользователя (свой или чужой).
///
/// Принадлежность текущему пользователю определяется сравнением [id]
/// с [UserProfileRepository.currentUserId], а не полем модели.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.avatarAsset,
    this.photoAssets = const [],
    this.bio,
    this.city,
    this.isVerified = false,
    this.isOrganizer = false,
    this.interestTags = const [],
    this.upcomingEvents = const [],
    this.pastEvents,
  });

  final String id;
  final String name;
  final String avatarAsset;

  /// Фото в hero; если пусто — только [avatarAsset].
  final List<String> photoAssets;

  final String? bio;
  final String? city;
  final bool isVerified;

  /// Организатор событий (для вкладки «Люди» и карточки профиля).
  final bool isOrganizer;

  /// Интересы / форматы: Пешком, Пикники.
  final List<String> interestTags;

  final List<ProfileEventPreview> upcomingEvents;

  /// `null` — организатор скрыл прошлые события.
  final List<ProfileEventPreview>? pastEvents;

  List<String> get heroPhotoAssets =>
      photoAssets.isNotEmpty ? photoAssets : [avatarAsset];

  bool get hasOrganizerActivity =>
      upcomingEvents.isNotEmpty || (pastEvents?.isNotEmpty ?? false);

  /// Строка для overlay вкладки «Люди»: «N событий» с правильным склонением.
  String? get peopleTabEventsLine {
    if (!isOrganizer || upcomingEvents.isEmpty) return null;
    return openEventsLabel(upcomingEvents.length);
  }

  /// Подпись под именем на вкладке «Люди».
  String? get peopleTabDetailLine {
    if (isOrganizer) {
      return interestTags.isNotEmpty ? interestTags.join(' · ') : null;
    }
    return bio;
  }

  /// «3 события» с правильным склонением.
  static String openEventsLabel(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return '$count событий';
    if (mod10 == 1) return '$count событие';
    if (mod10 >= 2 && mod10 <= 4) return '$count события';
    return '$count событий';
  }
}
