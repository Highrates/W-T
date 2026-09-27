import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../config/api_config.dart';
import '../config/firebase_config.dart';
import '../providers/auth_providers.dart';
import 'push_token_source.dart';

/// Регистрация FCM-токена через POST/DELETE /devices.
class DeviceRegistrationService {
  DeviceRegistrationService(this._ref, this._tokenSource);

  final Ref _ref;
  final PlatformPushTokenSource _tokenSource;

  String? _registeredToken;

  Future<void> registerIfNeeded() async {
    if (!ApiConfig.useApi) return;
    if (!_ref.read(authSessionProvider).isAuthenticated) return;

    final token = await _tokenSource.getToken();
    if (token == null || token.isEmpty) return;
    if (_registeredToken == token) return;

    await _ref.read(apiClientProvider).postJson(
          '/devices',
          auth: true,
          body: {
            'token': token,
            'platform': _tokenSource.platform,
          },
        );

    _registeredToken = token;
  }

  Future<void> unregisterIfNeeded() async {
    if (!ApiConfig.useApi) return;

    final token = _registeredToken ?? await _tokenSource.getToken();
    if (token == null || token.isEmpty) return;

    try {
      await _ref.read(apiClientProvider).deleteJson(
            '/devices',
            auth: true,
            body: {'token': token},
          );
    } catch (_) {}

    _registeredToken = null;
  }

  void listenTokenRefresh() {
    if (!FirebaseConfig.isConfigured) return;
    _tokenSource.firebase?.onTokenRefresh.listen((token) async {
      _registeredToken = null;
      if (token.isNotEmpty) {
        await registerIfNeeded();
      }
    });
  }
}

final deviceRegistrationServiceProvider = Provider<DeviceRegistrationService>((ref) {
  final service = DeviceRegistrationService(ref, PlatformPushTokenSource());
  service.listenTokenRefresh();
  return service;
});
