/// Шаги создания события (один экран compose; `route` — legacy).
enum CreateRouteStep {
  /// Текст, формат, участие, дата, точки.
  compose,

  /// Устаревший шаг карты (черновики мигрируют в compose).
  route;

  static const List<CreateRouteStep> ordered = [CreateRouteStep.compose];

  /// Миграция черновиков со старого wizard.
  static CreateRouteStep? fromStorageName(String? name) {
    if (name == null) return null;
    // Всё сводим к одному экрану.
    return CreateRouteStep.compose;
  }
}

extension CreateRouteStepX on CreateRouteStep {
  String get title => switch (this) {
        CreateRouteStep.compose => 'Новое событие',
        CreateRouteStep.route => 'Новое событие',
      };

  String get subtitle => '';

  CreateRouteStep? get next => null;

  CreateRouteStep? get previous => null;
}
