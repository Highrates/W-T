import '../../../features/shell/data/feed_filter_mock.dart';
import '../../../shared/models/walk_card_data.dart';
import '../../../shared/models/walk_card_join_status.dart';
import '../../../shared/models/walk_card_participant.dart';
import '../../../shared/models/walk_card_route_metric.dart';

/// Моки ленты cards. Фото — [assets/images/cards/](../../../assets/images/cards/).
abstract final class CardsFeedMock {
  static const String _cards = 'assets/images/cards';
  static const String _people = 'assets/images/people';

  static const _p1 = WalkCardParticipant(
    id: 'ivan',
    name: 'Иван Ургант',
    avatarAsset: '$_people/01.jpg',
  );
  static const _p2 = WalkCardParticipant(
    id: 'yulia',
    name: 'Анна Малиновская',
    avatarAsset: '$_people/02.jpg',
  );
  static const _p3 = WalkCardParticipant(
    id: 'maria',
    name: 'Мария Козлова',
    avatarAsset: '$_people/03.jpg',
  );
  static const _p4 = WalkCardParticipant(
    id: 'alexey',
    name: 'Алексей Петров',
    avatarAsset: '$_people/04.jpg',
  );
  static const _p5 = WalkCardParticipant(
    id: 'anna',
    name: 'Анна Смирнова',
    avatarAsset: '$_people/05.jpg',
  );

  static const WalkCardData sample = WalkCardData(
    id: 'dragons',
    whenLabel: 'Сегодня 13:15',
    goingLabel: '5/7 идут',
    routeMetric: WalkCardRouteMetric.points,
    routeMetricLabel: '8 точек',
    participants: [_p1, _p2, _p3, _p4, _p5],
    coverAssets: [
      '$_cards/01.jpg',
      '$_cards/02.jpg',
      '$_cards/03.jpg',
      '$_cards/04.jpg',
    ],
    organizerId: 'solomon',
    organizerName: 'Соломон Волков',
    organizerAvatarAsset: '$_people/04.jpg',
    title: 'Драконы и огни',
    description:
        'Предлагаю сегодня прогуляться по Терренкуру, устроить пикник, перекусить, пообщаться!',
    tags: ['Сочи 🌴', 'Пешком', 'Пикник'],
    formatIds: [FeedHotFilterMock.walkId],
    themeIds: [FeedHotFilterMock.cultureId, FeedHotFilterMock.foodId],
  );

  static const List<WalkCardData> feed = [
    sample,
    WalkCardData(
      id: 'terrenkur',
      isWhenHidden: true,
      goingLabel: '3/10 идут',
      routeMetric: WalkCardRouteMetric.points,
      routeMetricLabel: '12 точек',
      participants: [_p2, _p5],
      coverAssets: [
        '$_cards/05.jpg',
        '$_cards/06.jpg',
        '$_cards/07.jpg',
      ],
      organizerId: 'yulia',
      organizerName: 'Анна Малиновская',
      organizerAvatarAsset: '$_people/02.jpg',
      title: 'Terrenkur и кофе',
      description: 'Спокойный маршрут, остановки для фото и короткий пикник.',
      tags: ['Сочи 🌴', 'Пешком', 'Кофе'],
      formatIds: [FeedHotFilterMock.walkId],
      themeIds: [FeedHotFilterMock.natureId, FeedHotFilterMock.foodId],
    ),
    WalkCardData(
      id: 'sunset',
      whenLabel: 'Сб 18:30',
      goingLabel: '7/8 идут',
      routeMetric: WalkCardRouteMetric.distance,
      routeMetricLabel: '5,2 км',
      participants: [_p1, _p2, _p3, _p4, _p5, _p4, _p3],
      coverAssets: [
        '$_cards/08.jpg',
        '$_cards/09.jpg',
      ],
      organizerId: 'ivan',
      organizerName: 'Иван Ургант',
      organizerAvatarAsset: '$_people/01.jpg',
      isOrganizerVerified: true,
      title: 'Закат у моря',
      description: 'Короткая прогулка и встреча на набережной.',
      tags: ['Сочи 🌴', 'Компания', 'Закат'],
      formatIds: [FeedHotFilterMock.walkId],
      themeIds: [FeedHotFilterMock.natureId, FeedHotFilterMock.socialId],
      joinStatus: WalkCardJoinStatus.approved,
    ),
    WalkCardData(
      id: 'yoga-park',
      whenLabel: 'Вс 10:00',
      goingLabel: '4/12 идут',
      routeMetric: WalkCardRouteMetric.distance,
      routeMetricLabel: '3,1 км',
      participants: [_p3, _p4],
      coverAssets: [
        '$_cards/02.jpg',
        '$_cards/03.jpg',
      ],
      organizerId: 'anna',
      organizerName: 'Анна Смирнова',
      organizerAvatarAsset: '$_people/05.jpg',
      title: 'Йога в парке',
      description: 'Лёгкая практика на открытом воздухе и прогулка после.',
      tags: ['Сочи 🌴', 'Пешком', 'Спорт'],
      formatIds: [FeedHotFilterMock.walkId],
      themeIds: [FeedHotFilterMock.sportId, FeedHotFilterMock.natureId],
    ),
    WalkCardData(
      id: 'sochi-drive',
      whenLabel: 'Вс 9:00',
      goingLabel: '2/5 идут',
      routeMetric: WalkCardRouteMetric.points,
      routeMetricLabel: '4 точки',
      participants: [_p1],
      coverAssets: ['$_cards/06.jpg'],
      organizerId: 'ivan',
      organizerName: 'Иван Ургант',
      organizerAvatarAsset: '$_people/01.jpg',
      isOrganizerVerified: true,
      title: 'Красная Поляна на авто',
      description: 'Совместный выезд, остановки с видами и чай на маршруте.',
      tags: ['Сочи 🌴', 'Авто', 'Природа'],
      formatIds: [FeedHotFilterMock.driveId],
      themeIds: [FeedHotFilterMock.natureId],
    ),
    WalkCardData(
      id: 'banya-chill',
      whenLabel: 'Сб 16:00',
      goingLabel: '6/8 идут',
      routeMetric: WalkCardRouteMetric.distance,
      routeMetricLabel: '1,2 км',
      participants: [_p2, _p3, _p5],
      coverAssets: ['$_cards/07.jpg'],
      organizerId: 'yulia',
      organizerName: 'Анна Малиновская',
      organizerAvatarAsset: '$_people/02.jpg',
      title: 'Баня и неспешный вечер',
      description: 'Короткая прогулка до бани и отдых в компании.',
      tags: ['Сочи 🌴', 'Пешком', 'Отдых'],
      formatIds: [FeedHotFilterMock.walkId],
      themeIds: [FeedHotFilterMock.relaxId, FeedHotFilterMock.socialId],
    ),
    WalkCardData(
      id: 'text-tea-walk',
      whenLabel: 'Чт 17:30',
      goingLabel: '2/6 идут',
      routeMetric: WalkCardRouteMetric.distance,
      routeMetricLabel: '3,5 км',
      participants: [_p3],
      coverAssets: [],
      organizerId: 'maria',
      organizerName: 'Мария Козлова',
      organizerAvatarAsset: '$_people/03.jpg',
      title: 'Просто погулять и пообщаться',
      description:
          'Без фото и сложного маршрута — только хорошая компания, свежий воздух '
          'и разговоры. Встречаемся у фонтана в парке, идём вдоль набережной, '
          'можно зайти на чай. Подойдёт, если хочется лёгкого вечера без плана.',
      tags: ['Сочи 🌴', 'Пешком', 'Общение'],
      formatIds: [FeedHotFilterMock.walkId],
      themeIds: [FeedHotFilterMock.socialId],
    ),
  ];
}
