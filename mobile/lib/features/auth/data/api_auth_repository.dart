import '../../../core/api/api_client.dart';
import '../../../core/api/auth_session_mapper.dart';
import '../../../core/auth/auth_session.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> requestOtp({
    required AuthContactChannel channel,
    required String contact,
  }) async {
    final trimmed = contact.trim();
    switch (channel) {
      case AuthContactChannel.email:
        await _api.postJson(
          '/auth/email/request',
          body: {'email': trimmed.toLowerCase()},
        );
      case AuthContactChannel.phone:
        await _api.postJson(
          '/auth/phone/request',
          body: {'phone': trimmed},
        );
    }
  }

  @override
  Future<AuthSession> verifyOtp({
    required AuthContactChannel channel,
    required String contact,
    required String code,
  }) async {
    final trimmed = contact.trim();
    final Map<String, dynamic> json;

    switch (channel) {
      case AuthContactChannel.email:
        json = await _api.postJson(
          '/auth/email/verify',
          body: {'email': trimmed.toLowerCase(), 'code': code.trim()},
        );
      case AuthContactChannel.phone:
        json = await _api.postJson(
          '/auth/phone/verify',
          body: {'phone': trimmed, 'code': code.trim()},
        );
    }

    return sessionFromAuthResponse(json);
  }
}
