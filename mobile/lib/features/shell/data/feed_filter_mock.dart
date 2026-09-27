/// Ось фильтра ленты: участие, формат (как идём) или тема (что делаем).
enum FeedFilterAxis {
  participation,
  format,
  theme,
}

/// Горячий чип фильтра ленты.
class FeedHotFilter {
  const FeedHotFilter({
    required this.id,
    required this.label,
    required this.axis,
    required this.hint,
  });

  final String id;
  final String label;
  final FeedFilterAxis axis;

  /// Подсказка организатору: куда отнести событие.
  final String hint;
}

/// Таксономия фильтров ленты (без «Все» и без времени).
///
/// **Формат:** одна основная ось — пешком или на авто.
/// **Тема:** взаимоисключающие «ведущие» категории; у события может быть 1–2 темы.
abstract final class FeedHotFilterMock {
  static const String oneOnOneId = 'one_on_one';
  static const String groupId = 'group';

  static const String walkId = 'walk';
  static const String driveId = 'drive';

  static const String cultureId = 'culture';
  static const String natureId = 'nature';
  static const String foodId = 'food';
  static const String sportId = 'sport';
  static const String relaxId = 'relax';
  static const String socialId = 'social';

  static const String bikeId = 'bike';
  static const String photoId = 'photo';
  static const String kidsId = 'kids';
  static const String nightId = 'night';
  static const String dogId = 'dog';

  /// Первые чипы ленты: 1×1 / группа (до дивидера).
  static const List<FeedHotFilter> participationFilters = [
    FeedHotFilter(
      id: oneOnOneId,
      label: '🤝 1×1',
      axis: FeedFilterAxis.participation,
      hint: 'Ищу одного спутника',
    ),
    FeedHotFilter(
      id: groupId,
      label: '👥 Группа',
      axis: FeedFilterAxis.participation,
      hint: 'Групповое событие',
    ),
  ];

  static const List<FeedHotFilter> formatFilters = [
    FeedHotFilter(
      id: walkId,
      label: 'Пешком',
      axis: FeedFilterAxis.format,
      hint: 'Маршрут пешком, город, парк',
    ),
    FeedHotFilter(
      id: driveId,
      label: 'Авто',
      axis: FeedFilterAxis.format,
      hint: 'Выезд на машине, carpool',
    ),
  ];

  static const List<FeedHotFilter> themeFilters = [
    FeedHotFilter(
      id: cultureId,
      label: 'Культура',
      axis: FeedFilterAxis.theme,
      hint: 'Музеи, выставки, архитектура, экскурсии',
    ),
    FeedHotFilter(
      id: natureId,
      label: 'Природа',
      axis: FeedFilterAxis.theme,
      hint: 'Парки, море, горы, терренкур, закаты',
    ),
    FeedHotFilter(
      id: foodId,
      label: 'Еда',
      axis: FeedFilterAxis.theme,
      hint: 'Пикник, кофе, перекус по пути',
    ),
    FeedHotFilter(
      id: sportId,
      label: 'Спорт',
      axis: FeedFilterAxis.theme,
      hint: 'Йога, бег, тренировки, активный темп',
    ),
    FeedHotFilter(
      id: relaxId,
      label: 'Отдых',
      axis: FeedFilterAxis.theme,
      hint: 'Баня, spa, неспешный формат без спорта',
    ),
    FeedHotFilter(
      id: socialId,
      label: 'Общение',
      axis: FeedFilterAxis.theme,
      hint: 'Просто погулять и пообщаться, без жёсткой темы',
    ),
  ];

  /// Дополнительные теги только в wizard создания маршрута (не в ленте).
  static const List<FeedHotFilter> createRouteExtraFilters = [
    FeedHotFilter(
      id: bikeId,
      label: 'Велосипед',
      axis: FeedFilterAxis.theme,
      hint: 'Велопрогулка или bike-friendly маршрут',
    ),
    FeedHotFilter(
      id: photoId,
      label: 'Фото',
      axis: FeedFilterAxis.theme,
      hint: 'Остановки ради кадров и видов',
    ),
    FeedHotFilter(
      id: kidsId,
      label: 'С детьми',
      axis: FeedFilterAxis.theme,
      hint: 'Спокойный темп, подходит семьям',
    ),
    FeedHotFilter(
      id: nightId,
      label: 'Ночь',
      axis: FeedFilterAxis.theme,
      hint: 'Вечерний или ночной формат',
    ),
    FeedHotFilter(
      id: dogId,
      label: 'С собакой',
      axis: FeedFilterAxis.theme,
      hint: 'Pet-friendly маршрут',
    ),
  ];

  /// Лента: участие → формат → тема.
  static List<FeedHotFilter> get all => [
        ...participationFilters,
        ...formatFilters,
        ...themeFilters,
      ];

  /// Чипы после дивидера в ленте (без 1×1 / группы).
  static List<FeedHotFilter> get feedAfterDivider => [
        ...formatFilters,
        ...themeFilters,
      ];

  /// Wizard: формат/тема (+ extras), без оси участия (там отдельные сегменты).
  static List<FeedHotFilter> get createRouteAll => [
        ...formatFilters,
        ...themeFilters,
        ...createRouteExtraFilters,
      ];

  static FeedHotFilter? byId(String id) {
    for (final filter in [...all, ...createRouteExtraFilters]) {
      if (filter.id == id) return filter;
    }
    return null;
  }

  static bool isParticipationId(String id) =>
      participationFilters.any((filter) => filter.id == id);

  static bool isFormatId(String id) =>
      formatFilters.any((filter) => filter.id == id);

  static bool isThemeId(String id) =>
      themeFilters.any((filter) => filter.id == id) ||
      createRouteExtraFilters.any((filter) => filter.id == id);

  /// Пустой набор — вся лента. Внутри оси — ИЛИ, между осями — И.
  static bool matches({
    required Set<String> selectedIds,
    required List<String> formatIds,
    required List<String> themeIds,
    required bool isOneOnOne,
  }) {
    if (selectedIds.isEmpty) return true;

    final participation = selectedIds.where(isParticipationId).toSet();
    final formats = selectedIds.where(isFormatId).toSet();
    final themes = selectedIds.where(isThemeId).toSet();

    if (participation.isNotEmpty) {
      final wantOne = participation.contains(oneOnOneId);
      final wantGroup = participation.contains(groupId);
      if (wantOne && !wantGroup && !isOneOnOne) return false;
      if (wantGroup && !wantOne && isOneOnOne) return false;
    }

    if (formats.isNotEmpty && !formatIds.any(formats.contains)) {
      return false;
    }
    if (themes.isNotEmpty && !themeIds.any(themes.contains)) {
      return false;
    }
    return true;
  }
}
