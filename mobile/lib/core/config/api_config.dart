/// Базовый URL REST API (NestJS).
abstract final class ApiConfig {
  /// `--dart-define=API_BASE_URL=http://127.0.0.1:3000/api`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api',
  );

  /// `--dart-define=USE_MOCK_DATA=true` — mock-репозитории вместо API.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  /// Dev-only: `--dart-define=DEV_ACCESS_TOKEN=...` после curl auth/email/verify.
  static const String devAccessToken = String.fromEnvironment(
    'DEV_ACCESS_TOKEN',
    defaultValue: '',
  );

  /// Dev-only FCM token for POST /devices (until Firebase SDK is wired).
  static const String devFcmToken = String.fromEnvironment(
    'DEV_FCM_TOKEN',
    defaultValue: '',
  );

  static bool get isConfigured => baseUrl.isNotEmpty;

  static bool get useApi => isConfigured && !useMockData;

  /// WebSocket host for chat (`ws://127.0.0.1:3000` when API is local).
  static String get wsBaseUrl {
    final api = Uri.parse(baseUrl);
    final scheme = api.scheme == 'https' ? 'wss' : 'ws';
    final defaultPort = api.scheme == 'https' ? 443 : 80;
    final port = api.hasPort ? api.port : defaultPort;
    final portSuffix =
        (api.scheme == 'https' && port == 443) ||
                (api.scheme == 'http' && port == 80)
            ? ''
            : ':$port';
    return '$scheme://${api.host}$portSuffix';
  }
}
