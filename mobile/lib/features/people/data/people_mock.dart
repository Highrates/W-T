/// Профиль для свайп-ленты «Люди».
class PeopleProfile {
  const PeopleProfile({
    required this.id,
    required this.name,
    required this.isOrganizer,
    required this.photoAsset,
    this.bio,
    this.openEventsCount,
    this.tags,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final bool isOrganizer;

  /// Участник: одна–две строки под именем.
  final String? bio;

  /// Организатор: число предстоящих событий.
  final int? openEventsCount;

  /// Организатор: форматы / теги, напр. «Пешком · Пикники».
  final String? tags;

  /// `assets/images/people/01.jpg` и т.д.
  final String photoAsset;
  final bool isVerified;

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

/// Моки вкладки «Люди». Фото — [assets/images/people/](../../../assets/images/people/README.md).
abstract final class PeopleMock {
  static const List<PeopleProfile> profiles = [
    PeopleProfile(
      id: 'ivan',
      name: 'Иван Ургант',
      isOrganizer: true,
      openEventsCount: 3,
      tags: 'Пешком · Пикники',
      photoAsset: 'assets/images/people/01.jpg',
      isVerified: true,
    ),
    PeopleProfile(
      id: 'yulia',
      name: 'Анна Малиновская',
      isOrganizer: true,
      openEventsCount: 2,
      tags: 'Пикники',
      photoAsset: 'assets/images/people/02.jpg',
    ),
    PeopleProfile(
      id: 'maria',
      name: 'Мария Козлова',
      isOrganizer: false,
      bio: 'Люблю Terrenkur и пикники у моря',
      photoAsset: 'assets/images/people/03.jpg',
    ),
    PeopleProfile(
      id: 'alexey',
      name: 'Алексей Петров',
      isOrganizer: false,
      bio: 'Готов к длинным маршрутам и спонтанным прогулкам',
      photoAsset: 'assets/images/people/04.jpg',
    ),
    PeopleProfile(
      id: 'anna',
      name: 'Анна Смирнова',
      isOrganizer: true,
      openEventsCount: 8,
      tags: 'Авто · События',
      photoAsset: 'assets/images/people/05.jpg',
      isVerified: true,
    ),
  ];

  static List<PeopleProfile> filtered({required bool organizersOnly}) {
    if (!organizersOnly) return profiles;
    return profiles.where((p) => p.isOrganizer).toList(growable: false);
  }
}
