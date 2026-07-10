/// Базовый URL REST API (NestJS).
abstract final class ApiConfig {
  /// `--dart-define=API_BASE_URL=http://127.0.0.1:3000/api`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api',
  );

  static bool get isConfigured => baseUrl.isNotEmpty;
}
