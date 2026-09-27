import '../auth/auth_session.dart';

AuthSession sessionFromAuthResponse(Map<String, dynamic> json) {
  final user = json['user'];
  final userId = user is Map<String, dynamic> ? user['id'] as String? : null;

  return AuthSession(
    accessToken: json['accessToken'] as String?,
    refreshToken: json['refreshToken'] as String?,
    userId: userId,
  );
}
