import '../../../features/shell/data/feed_filter_mock.dart';
import '../../../shared/models/event_card_data.dart';
import '../../../shared/models/event_join_status.dart';
import '../../../shared/models/event_participant.dart';
import '../../../shared/models/event_route_metric.dart';

/// Моки ленты cards. Фото — [assets/images/cards/](../../../assets/images/cards/).
abstract final class CardsFeedMock {
  static const String _cards = 'assets/images/cards';
  static const String _people = 'assets/images/people';

  static const _p1 = EventParticipant(
    id: 'ivan',
    name: 'Иван Ургант',
    avatarAsset: '$_people/01.jpg',
  );
  static const _p2 = EventParticipant(
    id: 'yulia',
    name: 'Анна Малиновская',
    avatarAsset: '$_people/02.jpg',
  );
  static const _p3 = EventParticipant(
    id: 'maria',
    name: 'Мария Козлова',
    avatarAsset: '$_people/03.jpg',
  );
  static const _p4 = EventParticipant(
    id: 'alexey',
    name: 'Алексей Петров',
    avatarAsset: '$_people/04.jpg',
  );
  static const _p5 = EventParticipant(
    id: 'anna',
    name: 'Анна Смирнова',
    avatarAsset: '$_people/05.jpg',
  );

  static const EventCardData sample = EventCardData(
    id: 'dragons',
    whenLabel: 'Сегодня 13:15',
    goingLabel: '5/7 идут',
    routeMetric: EventRouteMetric.points,
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

  static const List<EventCardData> feed = [
    sample,
    EventCardData(
      id: 'terrenkur',
      isWhenHidden: true,
      goingLabel: '3/10 идут',
      routeMetric: EventRouteMetric.points,
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
    EventCardData(
      id: 'sunset',
      whenLabel: 'Сб 18:30',
      goingLabel: '7/8 идут',
      routeMetric: EventRouteMetric.distance,
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
      joinStatus: EventJoinStatus.approved,
    ),
    EventCardData(
      id: 'yoga-park',
      whenLabel: 'Вс 10:00',
      goingLabel: '4/12 идут',
      routeMetric: EventRouteMetric.distance,
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
    EventCardData(
      id: 'sochi-drive',
      whenLabel: 'Вс 9:00',
      goingLabel: '2/5 идут',
      routeMetric: EventRouteMetric.points,
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
    EventCardData(
      id: 'banya-chill',
      whenLabel: 'Сб 16:00',
      goingLabel: '6/8 идут',
      routeMetric: EventRouteMetric.points,
      routeMetricLabel: '1 точка',
      participants: [_p1, _p4],
      coverAssets: ['$_cards/banya.jpg'],
      organizerId: 'alexey',
      organizerName: 'Алексей Петров',
      organizerAvatarAsset: '$_people/04.jpg',
      title: 'Баня с мужиками',
      description:
          'Просто поход в баню — пар, чай и разговоры. Без прогулок и лишнего '
          'плана, только своя компания.',
      tags: ['Сочи 🌴', 'Отдых'],
      formatIds: [FeedHotFilterMock.walkId],
      themeIds: [FeedHotFilterMock.relaxId, FeedHotFilterMock.socialId],
    ),
    EventCardData(
      id: 'beer-bar',
      whenLabel: 'Пт 19:30',
      goingLabel: '4/6 идут',
      routeMetric: EventRouteMetric.points,
      routeMetricLabel: '2 точки',
      participants: [_p1, _p4],
      coverAssets: ['$_cards/bar.jpg'],
      organizerId: 'ivan',
      organizerName: 'Иван Ургант',
      organizerAvatarAsset: '$_people/01.jpg',
      isOrganizerVerified: true,
      title: 'Пивной бар и вечерний вайб',
      description:
          'Встречаемся у входа, берём пинту и болтаем. Без жёсткого плана — '
          'просто хороший вечер в компании.',
      tags: ['Сочи 🌴', 'Пешком', 'Еда'],
      formatIds: [FeedHotFilterMock.walkId],
      themeIds: [FeedHotFilterMock.foodId, FeedHotFilterMock.socialId],
    ),
    EventCardData(
      id: 'astrakhan-fishing',
      cityId: 'astrakhan',
      whenLabel: 'Сб 5:30',
      goingLabel: '3/5 идут',
      routeMetric: EventRouteMetric.points,
      routeMetricLabel: '3 точки',
      participants: [_p4, _p5],
      coverAssets: ['$_cards/fishing.jpg'],
      organizerId: 'alexey',
      organizerName: 'Алексей Петров',
      organizerAvatarAsset: '$_people/04.jpg',
      title: 'Рыбалка в Астрахани',
      description:
          'Ранний выезд на воду, снасти можно взять с собой или взять на месте. '
          'Уха вечером — по улову.',
      tags: ['Астрахань', 'Авто', 'Природа'],
      formatIds: [FeedHotFilterMock.driveId],
      themeIds: [FeedHotFilterMock.natureId, FeedHotFilterMock.relaxId],
    ),
    EventCardData(
      id: 'astrakhan-embankment',
      cityId: 'astrakhan',
      whenLabel: 'Вс 18:00',
      goingLabel: '2/6 идут',
      routeMetric: EventRouteMetric.distance,
      routeMetricLabel: '4,0 км',
      participants: [_p3],
      coverAssets: ['$_cards/11.jpg', '$_cards/12.jpg'],
      organizerId: 'maria',
      organizerName: 'Мария Козлова',
      organizerAvatarAsset: '$_people/03.jpg',
      title: 'Вечер на набережной Волги',
      description:
          'Неспешная прогулка по набережной, закат и кофе. Без жёсткого плана — '
          'просто выйти в город и поболтать.',
      tags: ['Астрахань', 'Пешком', 'Общение'],
      formatIds: [FeedHotFilterMock.walkId],
      themeIds: [FeedHotFilterMock.socialId, FeedHotFilterMock.natureId],
    ),
    EventCardData(
      id: 'pool-krasnaya-polyana',
      whenLabel: 'Вс 12:00',
      goingLabel: '5/10 идут',
      routeMetric: EventRouteMetric.distance,
      routeMetricLabel: '2,4 км',
      participants: [_p2, _p3, _p1],
      coverAssets: ['$_cards/pool-kp.jpg'],
      organizerId: 'anna',
      organizerName: 'Анна Смирнова',
      organizerAvatarAsset: '$_people/05.jpg',
      title: 'Бассейн в Красной Поляне',
      description:
          'Выезд в Поляну, купание и лёгкая прогулка вокруг. Кто на машине — '
          'пишите, соберём carpool.',
      tags: ['Сочи 🌴', 'Авто', 'Спорт'],
      formatIds: [FeedHotFilterMock.driveId],
      themeIds: [FeedHotFilterMock.sportId, FeedHotFilterMock.relaxId],
    ),
    EventCardData(
      id: 'text-tea-walk',
      whenLabel: 'Чт 17:30',
      goingLabel: '1/2 идут',
      isOneOnOne: true,
      routeMetric: EventRouteMetric.distance,
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
      tags: ['Сочи 🌴', 'Пешком', 'Общение', '1×1'],
      formatIds: [FeedHotFilterMock.walkId],
      themeIds: [FeedHotFilterMock.socialId],
    ),
    EventCardData(
      id: 'coffee-duo',
      whenLabel: 'Пт 11:00',
      goingLabel: '0/2 идут',
      isOneOnOne: true,
      routeMetric: EventRouteMetric.points,
      routeMetricLabel: '3 точки',
      participants: [],
      coverAssets: ['$_cards/10.jpg'],
      organizerId: 'anna',
      organizerName: 'Анна Смирнова',
      organizerAvatarAsset: '$_people/05.jpg',
      title: 'Кофе и набережная вдвоём',
      description: 'Спокойная прогулка и кофе — ищу одного компаньона.',
      tags: ['Сочи 🌴', 'Пешком', 'Кофе', '1×1'],
      formatIds: [FeedHotFilterMock.walkId],
      themeIds: [FeedHotFilterMock.foodId, FeedHotFilterMock.socialId],
    ),
  ];
}
