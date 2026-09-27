import '../domain/route_template_summary.dart';
import 'templates_repository.dart';

class MockTemplatesRepository implements TemplatesRepository {
  const MockTemplatesRepository();

  static const _items = [
    RouteTemplateSummary(
      id: 'tpl-terrenkur',
      title: 'Терренкур',
      pointCount: 4,
      cityId: 'sochi',
    ),
  ];

  @override
  Future<List<RouteTemplateSummary>> listMine() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _items;
  }

  @override
  Future<String> spawnOccurrence(
    String templateId, {
    required DateTime scheduledAt,
    String? title,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'spawned-$templateId';
  }
}
