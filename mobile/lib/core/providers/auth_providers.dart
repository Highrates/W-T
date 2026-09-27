import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../api/auth_session_mapper.dart';
import '../auth/auth_session.dart';
import '../auth/auth_session_storage.dart';
import '../config/api_config.dart';
import '../push/device_registration_service.dart';

class AuthSessionNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() {
    _bootstrap();
    return const AuthSession.empty();
  }

  Future<void> _bootstrap() async {
    var session = await AuthSessionStorage.load();

    if (!session.isAuthenticated && ApiConfig.devAccessToken.isNotEmpty) {
      session = AuthSession(accessToken: ApiConfig.devAccessToken);
      await AuthSessionStorage.save(session);
    }

    if (session.isAuthenticated && session.userId == null) {
      session = await _hydrateUserId(session);
    }

    state = session;

    if (session.isAuthenticated) {
      await ref.read(deviceRegistrationServiceProvider).registerIfNeeded();
    }
  }

  Future<void> setSession(AuthSession session) async {
    await AuthSessionStorage.save(session);
    var next = session;
    if (next.isAuthenticated && next.userId == null) {
      next = await _hydrateUserId(next);
    }
    state = next;
    if (next.isAuthenticated) {
      await ref.read(deviceRegistrationServiceProvider).registerIfNeeded();
    }
  }

  Future<void> clear() async {
    await ref.read(deviceRegistrationServiceProvider).unregisterIfNeeded();
    await AuthSessionStorage.clear();
    state = const AuthSession.empty();
  }

  /// POST /auth/refresh — ротация access + refresh в storage.
  Future<bool> refreshSession() async {
    final refreshToken = state.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/refresh');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;

      var next = sessionFromAuthResponse(decoded);
      if (next.userId == null) {
        next = next.copyWith(userId: state.userId);
      }
      if (next.userId == null) {
        next = await _hydrateUserId(next);
      }

      await AuthSessionStorage.save(next);
      state = next;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AuthSession> _hydrateUserId(AuthSession session) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/me');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.statusCode != 200) return session;

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return session;

      final userId = json['id'] as String?;
      if (userId == null) return session;

      final next = session.copyWith(userId: userId);
      await AuthSessionStorage.save(next);
      return next;
    } catch (_) {
      return session;
    }
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession>(AuthSessionNotifier.new);
