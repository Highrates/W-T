import 'dart:io';

import '../config/api_config.dart';
import '../config/firebase_config.dart';
import 'firebase_messaging_token_source.dart';

/// Источник FCM-токена устройства.
abstract class PushTokenSource {
  Future<String?> getToken();
}

/// Dev / CI: `--dart-define=DEV_FCM_TOKEN=...`
class DevPushTokenSource implements PushTokenSource {
  @override
  Future<String?> getToken() async {
    final token = ApiConfig.devFcmToken.trim();
    return token.isEmpty ? null : token;
  }
}

class PlatformPushTokenSource implements PushTokenSource {
  PlatformPushTokenSource({
    DevPushTokenSource? dev,
    FirebaseMessagingTokenSource? firebase,
  })  : _dev = dev ?? DevPushTokenSource(),
        _firebase = firebase ?? FirebaseMessagingTokenSource();

  final DevPushTokenSource _dev;
  final FirebaseMessagingTokenSource _firebase;

  @override
  Future<String?> getToken() async {
    final dev = await _dev.getToken();
    if (dev != null) return dev;

    if (FirebaseConfig.isConfigured) {
      return _firebase.getToken();
    }

    return null;
  }

  String get platform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'android';
  }

  FirebaseMessagingTokenSource? get firebase => _firebase;
}
