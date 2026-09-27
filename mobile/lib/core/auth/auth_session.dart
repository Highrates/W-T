/// JWT-сессия (access + опционально refresh и userId).
class AuthSession {
  const AuthSession({
    this.accessToken,
    this.refreshToken,
    this.userId,
  });

  const AuthSession.empty()
      : accessToken = null,
        refreshToken = null,
        userId = null;

  final String? accessToken;
  final String? refreshToken;
  final String? userId;

  bool get isAuthenticated =>
      accessToken != null && accessToken!.trim().isNotEmpty;

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    String? userId,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
    );
  }
}
