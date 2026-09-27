import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_session.dart';
import 'reports_repository.dart';

class ApiReportsRepository implements ReportsRepository {
  ApiReportsRepository(this._api, this._readAuth);

  final ApiClient _api;
  final AuthSession Function() _readAuth;

  @override
  Future<void> submitReport({
    String? targetUserId,
    String? occurrenceId,
    required ReportReason reason,
    String? comment,
  }) async {
    if (!_readAuth().isAuthenticated) {
      throw StateError('Auth required');
    }

    await _api.postJson(
      '/reports',
      auth: true,
      body: {
        if (targetUserId != null) 'targetUserId': targetUserId,
        if (occurrenceId != null) 'occurrenceId': occurrenceId,
        'reason': reason.apiValue,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
  }
}
