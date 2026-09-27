import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../shared/models/profile_event_preview.dart';
import '../../../shared/models/user_profile.dart';
import '../../event/data/event_api_mapper.dart';
import 'user_profile_repository.dart';

class ApiUserProfileRepository implements UserProfileRepository {
  ApiUserProfileRepository(this._api, this._readAuth);

  final ApiClient _api;
  final AuthSession Function() _readAuth;

  @override
  String get currentUserId =>
      _readAuth().userId ?? '00000000-0000-0000-0000-000000000000';

  @override
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final json = await _api.getJson('/users/$userId');
      return userProfileFromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<ProfileEventPreview>> getGoingEvents(String userId) async {
    if (!_readAuth().isAuthenticated || _readAuth().userId != userId) {
      return const [];
    }

    final json = await _api.getJson(
      '/users/me/participations',
      query: {'upcoming': 'true'},
      auth: true,
    );

    final items = json['items'];
    if (items is! List) return const [];

    return [
      for (final item in items)
        if (item is Map<String, dynamic>)
          ProfileEventPreview(
            eventId: (item['event'] as Map<String, dynamic>?)?['id']
                    as String? ??
                '',
            title: (item['event'] as Map<String, dynamic>?)?['title']
                    as String? ??
                '',
            coverAsset: _coverFromEvent(item['event']),
            goingLabel: (item['event'] as Map<String, dynamic>?)?['goingLabel']
                    as String? ??
                '',
          ),
    ];
  }

  @override
  Future<List<ProfileEventPreview>> getGoingPastEvents(String userId) async {
    if (!_readAuth().isAuthenticated || _readAuth().userId != userId) {
      return const [];
    }

    final json = await _api.getJson(
      '/users/me/participations',
      query: {'upcoming': 'false'},
      auth: true,
    );

    final items = json['items'];
    if (items is! List) return const [];

    return [
      for (final item in items)
        if (item is Map<String, dynamic>)
          ProfileEventPreview(
            eventId: (item['event'] as Map<String, dynamic>?)?['id']
                    as String? ??
                '',
            title: (item['event'] as Map<String, dynamic>?)?['title']
                    as String? ??
                '',
            coverAsset: _coverFromEvent(item['event']),
            goingLabel: (item['event'] as Map<String, dynamic>?)?['goingLabel']
                    as String? ??
                '',
            isPast: true,
          ),
    ];
  }

  @override
  Future<String?> updateAvatarUrl(String avatarUrl) async {
    if (!_readAuth().isAuthenticated) return null;

    final json = await _api.patchJson(
      '/users/me',
      auth: true,
      body: {'avatarUrl': avatarUrl},
    );

    return json['avatarUrl'] as String?;
  }

  String _coverFromEvent(Object? eventJson) {
    if (eventJson is! Map<String, dynamic>) {
      return 'assets/images/people/04.jpg';
    }
    final coverUrl = eventJson['coverUrl'] as String?;
    if (coverUrl != null && coverUrl.isNotEmpty) return coverUrl;
    return 'assets/images/people/04.jpg';
  }
}
