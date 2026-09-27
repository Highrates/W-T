import 'package:shared_preferences/shared_preferences.dart';

import 'auth_session.dart';

/// Локальное хранение JWT до экрана auth.
abstract final class AuthSessionStorage {
  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _userIdKey = 'auth_user_id';

  static Future<AuthSession> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AuthSession(
      accessToken: prefs.getString(_accessKey),
      refreshToken: prefs.getString(_refreshKey),
      userId: prefs.getString(_userIdKey),
    );
  }

  static Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await _write(prefs, _accessKey, session.accessToken);
    await _write(prefs, _refreshKey, session.refreshToken);
    await _write(prefs, _userIdKey, session.userId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userIdKey);
  }

  static Future<void> _write(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }
}
