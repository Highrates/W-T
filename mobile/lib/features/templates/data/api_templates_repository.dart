import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_session.dart';
import '../domain/route_template_summary.dart';
import 'templates_repository.dart';

class ApiTemplatesRepository implements TemplatesRepository {
  ApiTemplatesRepository(this._api, this._readAuth);

  final ApiClient _api;
  final AuthSession Function() _readAuth;

  @override
  Future<List<RouteTemplateSummary>> listMine() async {
    if (!_readAuth().isAuthenticated) return const [];

    final json = await _api.getJson('/templates/me', auth: true);
    final items = json['items'];
    if (items is! List) return const [];

    return [
      for (final item in items)
        if (item is Map<String, dynamic>) _mapTemplate(item),
    ];
  }

  @override
  Future<String> spawnOccurrence(
    String templateId, {
    required DateTime scheduledAt,
    String? title,
  }) async {
    final json = await _api.postJson(
      '/templates/$templateId/occurrences',
      auth: true,
      body: {
        'scheduledAt': scheduledAt.toIso8601String(),
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      },
    );

    return json['id'] as String? ?? '';
  }

  RouteTemplateSummary _mapTemplate(Map<String, dynamic> json) {
    final updatedRaw = json['updatedAt'] as String?;

    return RouteTemplateSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Шаблон',
      pointCount: json['pointCount'] as int? ?? 0,
      cityId: json['cityId'] as String?,
      updatedAt: updatedRaw != null ? DateTime.tryParse(updatedRaw) : null,
    );
  }
}
