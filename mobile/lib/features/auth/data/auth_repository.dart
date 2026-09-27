import '../../../core/auth/auth_session.dart';

enum AuthContactChannel { email, phone }

/// OTP-авторизация (email или телефон).
abstract class AuthRepository {
  Future<void> requestOtp({
    required AuthContactChannel channel,
    required String contact,
  });

  Future<AuthSession> verifyOtp({
    required AuthContactChannel channel,
    required String contact,
    required String code,
  });
}
