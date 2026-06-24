/// Конфигурация Яндекс API.
///
/// На клиенте хранится **только** ключ MapKit Mobile SDK.
/// Геокодер / Геосаджест / Поиск организаций — на бэкенде (см. docs/MAPS.md).
abstract final class YandexConfig {
  /// `--dart-define=MAPKIT_API_KEY=...`
  static const String mapkitApiKey = String.fromEnvironment('MAPKIT_API_KEY');

  static bool get hasMapkitKey => mapkitApiKey.isNotEmpty;
}
