import '../../../features/cards/data/cards_feed_mock.dart';
import '../../../shared/models/event_card_data.dart';

/// Краткая карточка для выбора «из прошлого» или «шаблона».
class CreateRouteSourceOption {
  const CreateRouteSourceOption({
    required this.id,
    required this.title,
    required this.subtitle,
    this.coverAsset,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? coverAsset;
}

/// Mock: прошлые маршруты текущего пользователя и системные шаблоны.
abstract final class CreateRouteSourcesMock {
  /// События, где текущий пользователь — организатор (mock user id).
  static const String currentOrganizerId = 'solomon';

  static List<EventCardData> get myPreviousEvents => CardsFeedMock.feed
      .where((event) => event.organizerId == currentOrganizerId)
      .toList(growable: false);

  static List<CreateRouteSourceOption> get previousOptions => [
        for (final event in myPreviousEvents)
          CreateRouteSourceOption(
            id: event.id,
            title: event.title,
            subtitle: event.whenLabel ?? 'Без даты',
            coverAsset: event.primaryCoverAsset,
          ),
      ];

  static const List<CreateRouteSourceOption> templateOptions = [
    CreateRouteSourceOption(
      id: 'tpl_terrenkur',
      title: 'Терренкур + кофе',
      subtitle: 'Пешком · природа · 2–3 часа',
      coverAsset: 'assets/images/cards/05.jpg',
    ),
    CreateRouteSourceOption(
      id: 'tpl_culture_walk',
      title: 'Культурная прогулка',
      subtitle: 'Пешком · музеи и архитектура',
      coverAsset: 'assets/images/cards/02.jpg',
    ),
    CreateRouteSourceOption(
      id: 'tpl_drive_sunset',
      title: 'Закат на машине',
      subtitle: 'Авто · природа · 1–2 остановки',
      coverAsset: 'assets/images/cards/08.jpg',
    ),
  ];

  static EventCardData? previousEventById(String id) {
    for (final event in myPreviousEvents) {
      if (event.id == id) return event;
    }
    return null;
  }
}
