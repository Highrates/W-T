import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_token_source.dart';

/// Live FCM token via Firebase Messaging SDK.
class FirebaseMessagingTokenSource implements PushTokenSource {
  FirebaseMessagingTokenSource({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<String?> getToken() async {
    try {
      await _messaging.requestPermission();
      return _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
