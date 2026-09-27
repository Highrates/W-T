/// Причина жалобы (совпадает с backend ReportReason).
enum ReportReason {
  spam,
  inappropriate,
  harassment,
  fake,
  other,
}

abstract interface class ReportsRepository {
  Future<void> submitReport({
    String? targetUserId,
    String? occurrenceId,
    required ReportReason reason,
    String? comment,
  });
}

extension ReportReasonApi on ReportReason {
  String get apiValue => name.toUpperCase();
}
