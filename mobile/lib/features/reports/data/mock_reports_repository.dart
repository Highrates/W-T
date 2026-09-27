import 'reports_repository.dart';

class MockReportsRepository implements ReportsRepository {
  const MockReportsRepository();

  @override
  Future<void> submitReport({
    String? targetUserId,
    String? occurrenceId,
    required ReportReason reason,
    String? comment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
