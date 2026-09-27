import '../domain/route_template_summary.dart';

abstract interface class TemplatesRepository {
  Future<List<RouteTemplateSummary>> listMine();

  Future<String> spawnOccurrence(
    String templateId, {
    required DateTime scheduledAt,
    String? title,
  });
}
