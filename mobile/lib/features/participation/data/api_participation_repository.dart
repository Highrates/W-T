import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../shared/models/event_join_status.dart';
import '../../event/data/event_api_mapper.dart';
import '../domain/event_participation.dart';
import 'participation_repository.dart';

class ApiParticipationRepository implements ParticipationRepository {
  ApiParticipationRepository(this._api, this._readAuth);

  final ApiClient _api;
  final AuthSession Function() _readAuth;

  void _requireAuth() {
    if (!_readAuth().isAuthenticated) {
      throw ApiException('Войдите в аккаунт');
    }
  }

  @override
  Future<EventJoinStatus> submitJoin(String eventId) async {
    _requireAuth();

    final json = await _api.postJson(
      '/occurrences/$eventId/join',
      auth: true,
    );

    return parseJoinStatus(json['joinStatus'] as String?);
  }

  @override
  Future<void> leave(String eventId) async {
    _requireAuth();

    await _api.postJson(
      '/occurrences/$eventId/leave',
      auth: true,
    );
  }

  @override
  Future<List<EventParticipation>> listParticipations(String eventId) async {
    _requireAuth();

    final json = await _api.getJson(
      '/occurrences/$eventId/participations',
      auth: true,
    );

    final items = json['items'];
    if (items is! List) return const [];

    return [
      for (final item in items)
        if (item is Map<String, dynamic>) _mapParticipation(item),
    ];
  }

  @override
  Future<void> updateParticipation(
    String participationId, {
    required bool accept,
  }) async {
    _requireAuth();

    await _api.patchJson(
      '/participations/$participationId',
      auth: true,
      body: {'status': accept ? 'accepted' : 'rejected'},
    );
  }

  EventParticipation _mapParticipation(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final avatarUrl = user['avatarUrl'] as String?;

    return EventParticipation(
      id: json['id'] as String? ?? '',
      userId: user['id'] as String? ?? '',
      name: user['name'] as String? ?? 'Участник',
      avatarAsset: avatarUrl != null && avatarUrl.isNotEmpty ? avatarUrl : null,
      bio: user['bio'] as String?,
      isVerified: user['isVerified'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
