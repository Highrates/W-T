import '../../../shared/models/profile_event_preview.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/event_card_data.dart';
import '../../cards/data/cards_feed_mock.dart';
import 'user_profile_repository.dart';

/// Мок-реализация [UserProfileRepository].
class MockUserProfileRepository implements UserProfileRepository {
  const MockUserProfileRepository();

  @override
  String get currentUserId => 'yulia';

  static const String _people = 'assets/images/people';
  static const String _cards = 'assets/images/cards';

  static ProfileEventPreview _previewFromCard(
    EventCardData card, {
    required bool isPast,
  }) {
    return ProfileEventPreview(
      eventId: card.id,
      title: card.title,
      coverAsset: card.primaryCoverAsset ?? card.organizerAvatarAsset,
      whenLabel: card.whenLabel,
      isWhenHidden: card.isWhenHidden,
      goingLabel: card.goingLabel,
      isPast: isPast,
    );
  }

  static final Map<String, UserProfile> _profiles = {
    'ivan': UserProfile(
      id: 'ivan',
      name: 'Иван Ургант',
      avatarAsset: '$_people/01.jpg',
      isOrganizer: true,
      photoAssets: [
        '$_people/01.jpg',
        '$_cards/08.jpg',
        '$_cards/09.jpg',
      ],
      city: 'Сочи',
      bio: 'Организую прогулки у моря и пикники на Terrenkur',
      isVerified: true,
      interestTags: const ['Пешком', 'Пикники'],
      upcomingEvents: [
        _previewFromCard(CardsFeedMock.feed[2], isPast: false),
        const ProfileEventPreview(
          eventId: 'upcoming-ivan-1',
          title: 'Пикник в парке Ривьера',
          coverAsset: '$_cards/03.jpg',
          whenLabel: 'Вс 11:00',
          goingLabel: '4/8 идут',
        ),
        const ProfileEventPreview(
          eventId: 'upcoming-ivan-2',
          title: 'Terrenkur на рассвете',
          coverAsset: '$_cards/05.jpg',
          whenLabel: 'Ср 07:30',
          goingLabel: '2/6 идут',
        ),
        const ProfileEventPreview(
          eventId: 'upcoming-ivan-3',
          title: 'Набережная и кофе',
          coverAsset: '$_cards/12.jpg',
          whenLabel: 'Пт 17:00',
          goingLabel: '6/10 идут',
        ),
      ],
      pastEvents: const [
        ProfileEventPreview(
          eventId: 'past-ivan-1',
          title: 'Утро на Мамайке',
          coverAsset: '$_cards/10.jpg',
          whenLabel: '12 янв',
          goingLabel: '6/6 идут',
          isPast: true,
        ),
        ProfileEventPreview(
          eventId: 'past-ivan-2',
          title: 'Зимний Terrenkur',
          coverAsset: '$_cards/06.jpg',
          whenLabel: '28 дек',
          goingLabel: '8/8 идут',
          isPast: true,
        ),
        ProfileEventPreview(
          eventId: 'past-ivan-3',
          title: 'Огни в парке',
          coverAsset: '$_cards/04.jpg',
          whenLabel: '15 дек',
          goingLabel: '5/7 идут',
          isPast: true,
        ),
        ProfileEventPreview(
          eventId: 'past-ivan-4',
          title: 'Прогулка к маяку',
          coverAsset: '$_cards/02.jpg',
          whenLabel: '3 ноя',
          goingLabel: '4/5 идут',
          isPast: true,
        ),
      ],
    ),
    'yulia': UserProfile(
      id: 'yulia',
      name: 'Анна Малиновская',
      avatarAsset: '$_people/02.jpg',
      isOrganizer: true,
      photoAssets: ['$_people/02.jpg', '$_cards/06.jpg'],
      city: 'Сочи',
      bio: 'Спокойные маршруты, кофе и фото по пути',
      interestTags: const ['Пешком', 'Кофе'],
      upcomingEvents: [
        _previewFromCard(CardsFeedMock.feed[1], isPast: false),
        const ProfileEventPreview(
          eventId: 'upcoming-yulia-1',
          title: 'Кофе и смотровая',
          coverAsset: '$_cards/07.jpg',
          whenLabel: 'Вс 10:00',
          goingLabel: '3/6 идут',
        ),
        const ProfileEventPreview(
          eventId: 'upcoming-yulia-2',
          title: 'Лесная тропа',
          coverAsset: '$_cards/13.jpg',
          whenLabel: 'Чт 16:30',
          goingLabel: '1/8 идут',
        ),
      ],
      pastEvents: const [
        ProfileEventPreview(
          eventId: 'past-yulia-1',
          title: 'Осенний Terrenkur',
          coverAsset: '$_cards/05.jpg',
          whenLabel: '20 окт',
          goingLabel: '7/7 идут',
          isPast: true,
        ),
        ProfileEventPreview(
          eventId: 'past-yulia-2',
          title: 'Утренний кофе у моря',
          coverAsset: '$_cards/09.jpg',
          whenLabel: '8 сен',
          goingLabel: '4/6 идут',
          isPast: true,
        ),
        ProfileEventPreview(
          eventId: 'past-yulia-3',
          title: 'Фото-прогулка',
          coverAsset: '$_cards/14.jpg',
          whenLabel: '22 авг',
          goingLabel: '5/5 идут',
          isPast: true,
        ),
      ],
    ),
    'maria': const UserProfile(
      id: 'maria',
      name: 'Мария Козлова',
      avatarAsset: '$_people/03.jpg',
      isOrganizer: false,
      photoAssets: ['$_people/03.jpg', '$_cards/07.jpg'],
      city: 'Сочи',
      bio: 'Люблю Terrenkur и пикники у моря',
      interestTags: ['Пешком', 'Пикники'],
    ),
    'alexey': const UserProfile(
      id: 'alexey',
      name: 'Алексей Петров',
      avatarAsset: '$_people/04.jpg',
      isOrganizer: false,
      city: 'Сочи',
      bio: 'Готов к длинным маршрутам и спонтанным прогулкам',
      interestTags: ['Пешком'],
    ),
    'anna': const UserProfile(
      id: 'anna',
      name: 'Анна Смирнова',
      avatarAsset: '$_people/05.jpg',
      isOrganizer: true,
      city: 'Сочи',
      bio: 'Авто-маршруты и тематические встречи',
      isVerified: true,
      interestTags: ['Авто', 'События'],
      upcomingEvents: [
        ProfileEventPreview(
          eventId: 'upcoming-anna-1',
          title: 'Поездка в Красную Поляну',
          coverAsset: '$_cards/15.jpg',
          whenLabel: 'Сб 09:00',
          goingLabel: '3/4 идут',
        ),
        ProfileEventPreview(
          eventId: 'upcoming-anna-2',
          title: 'Встреча у моря',
          coverAsset: '$_cards/08.jpg',
          whenLabel: 'Пн 19:00',
          goingLabel: '5/8 идут',
        ),
        ProfileEventPreview(
          eventId: 'upcoming-anna-3',
          title: 'Вечерний город',
          coverAsset: '$_cards/11.jpg',
          whenLabel: 'Ср 20:30',
          goingLabel: '2/5 идут',
        ),
      ],
      pastEvents: [
        ProfileEventPreview(
          eventId: 'past-anna-1',
          title: 'Авто-тур по побережью',
          coverAsset: '$_cards/01.jpg',
          whenLabel: '6 янв',
          goingLabel: '4/4 идут',
          isPast: true,
        ),
        ProfileEventPreview(
          eventId: 'past-anna-2',
          title: 'Йога на пляже',
          coverAsset: '$_cards/03.jpg',
          whenLabel: '18 дек',
          goingLabel: '6/8 идут',
          isPast: true,
        ),
      ],
    ),
    'solomon': UserProfile(
      id: 'solomon',
      name: 'Соломон Волков',
      avatarAsset: '$_people/04.jpg',
      isOrganizer: true,
      city: 'Сочи',
      bio: 'Большие компании, пикники и длинные маршруты',
      interestTags: const ['Пешком', 'Пикник'],
      upcomingEvents: [
        _previewFromCard(CardsFeedMock.feed[0], isPast: false),
        const ProfileEventPreview(
          eventId: 'upcoming-solomon-1',
          title: 'Большой пикник',
          coverAsset: '$_cards/02.jpg',
          whenLabel: 'Завтра 14:00',
          goingLabel: '6/12 идут',
        ),
        const ProfileEventPreview(
          eventId: 'upcoming-solomon-2',
          title: 'Драконы: продолжение',
          coverAsset: '$_cards/04.jpg',
          whenLabel: 'Вс 12:00',
          goingLabel: '8/10 идут',
        ),
      ],
      pastEvents: const [
        ProfileEventPreview(
          eventId: 'past-solomon-1',
          title: 'Вечер в парке',
          coverAsset: '$_cards/11.jpg',
          whenLabel: '5 янв',
          goingLabel: '4/6 идут',
          isPast: true,
        ),
        ProfileEventPreview(
          eventId: 'past-solomon-2',
          title: 'Огни и музыка',
          coverAsset: '$_cards/01.jpg',
          whenLabel: '21 дек',
          goingLabel: '9/10 идут',
          isPast: true,
        ),
        ProfileEventPreview(
          eventId: 'past-solomon-3',
          title: 'Закрытие сезона',
          coverAsset: '$_cards/03.jpg',
          whenLabel: '10 ноя',
          goingLabel: '7/7 идут',
          isPast: true,
        ),
      ],
    ),
  };

  static const _goingEvents = <String, List<ProfileEventPreview>>{
    'yulia': [
      ProfileEventPreview(
        eventId: 'terrenkur',
        title: 'Terrenkur на рассвете',
        coverAsset: '$_cards/05.jpg',
        whenLabel: 'Сб 07:00',
        goingLabel: '12/15 идут',
      ),
      ProfileEventPreview(
        eventId: 'going-yulia-1',
        title: 'Пикник в парке Ривьера',
        coverAsset: '$_cards/03.jpg',
        whenLabel: 'Вс 14:00',
        goingLabel: '5/8 идут',
      ),
    ],
  };

  static const _goingPastEvents = <String, List<ProfileEventPreview>>{
    'yulia': [
      ProfileEventPreview(
        eventId: 'going-past-yulia-1',
        title: 'Набережная и закат',
        coverAsset: '$_cards/08.jpg',
        whenLabel: '15 окт',
        goingLabel: '8/8 идут',
        isPast: true,
      ),
    ],
  };

  @override
  Future<UserProfile?> getProfile(String userId) async => _profiles[userId];

  @override
  Future<List<ProfileEventPreview>> getGoingEvents(String userId) async =>
      _goingEvents[userId] ?? const [];

  @override
  Future<List<ProfileEventPreview>> getGoingPastEvents(String userId) async =>
      _goingPastEvents[userId] ?? const [];

  @override
  Future<String?> updateAvatarUrl(String avatarUrl) async => avatarUrl;
}
