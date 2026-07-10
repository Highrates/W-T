/// Шаги wizard создания маршрута (логический порядок заполнения).
enum CreateRouteStep {
  /// Новый / из прошлого / шаблон.
  source,

  /// Формат (пешком/авто) + тематика (multi-select).
  formatAndTheme,

  /// Название, описание, город.
  basics,

  /// Дата и время события.
  schedule,

  /// Точки маршрута на карте.
  routePoints,

  /// Описание и фото каждой точки.
  pointDetails,

  /// Обложки (опционально).
  photos,

  /// Лимит участников, 1×1, режим join.
  participation,

  /// Превью и публикация.
  review,
}

extension CreateRouteStepX on CreateRouteStep {
  String get title => switch (this) {
        CreateRouteStep.source => 'Как создаём?',
        CreateRouteStep.formatAndTheme => 'Формат и тема',
        CreateRouteStep.basics => 'О маршруте',
        CreateRouteStep.schedule => 'Когда',
        CreateRouteStep.routePoints => 'Точки маршрута',
        CreateRouteStep.pointDetails => 'Описание точек',
        CreateRouteStep.photos => 'Фото',
        CreateRouteStep.participation => 'Участие',
        CreateRouteStep.review => 'Проверка',
      };

  String get subtitle => switch (this) {
        CreateRouteStep.source =>
          'Новый маршрут или на основе того, что уже было',
        CreateRouteStep.formatAndTheme => '',
        CreateRouteStep.basics => '',
        CreateRouteStep.schedule =>
          'Дата и время начала; можно скрыть точное время',
        CreateRouteStep.routePoints =>
          'Найдите место или отметьте на карте — старт и финиш обязательны',
        CreateRouteStep.pointDetails => 'Расскажите о каждой точке',
        CreateRouteStep.photos =>
          'Обложки для ленты — необязательно; можно добавить с телефона',
        CreateRouteStep.participation => '',
        CreateRouteStep.review =>
          'Проверьте и опубликуйте — черновик сохранится локально',
      };

  CreateRouteStep? get next => switch (this) {
        CreateRouteStep.source => CreateRouteStep.formatAndTheme,
        CreateRouteStep.formatAndTheme => CreateRouteStep.basics,
        CreateRouteStep.basics => CreateRouteStep.schedule,
        CreateRouteStep.schedule => CreateRouteStep.routePoints,
        CreateRouteStep.routePoints => CreateRouteStep.pointDetails,
        CreateRouteStep.pointDetails => CreateRouteStep.photos,
        CreateRouteStep.photos => CreateRouteStep.participation,
        CreateRouteStep.participation => CreateRouteStep.review,
        CreateRouteStep.review => null,
      };

  CreateRouteStep? get previous => switch (this) {
        CreateRouteStep.source => null,
        CreateRouteStep.formatAndTheme => CreateRouteStep.source,
        CreateRouteStep.basics => CreateRouteStep.formatAndTheme,
        CreateRouteStep.schedule => CreateRouteStep.basics,
        CreateRouteStep.routePoints => CreateRouteStep.schedule,
        CreateRouteStep.pointDetails => CreateRouteStep.routePoints,
        CreateRouteStep.photos => CreateRouteStep.pointDetails,
        CreateRouteStep.participation => CreateRouteStep.photos,
        CreateRouteStep.review => CreateRouteStep.participation,
      };

  static const List<CreateRouteStep> ordered = CreateRouteStep.values;
}
