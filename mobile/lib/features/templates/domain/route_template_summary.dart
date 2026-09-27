class RouteTemplateSummary {
  const RouteTemplateSummary({
    required this.id,
    required this.title,
    required this.pointCount,
    this.cityId,
    this.updatedAt,
  });

  final String id;
  final String title;
  final int pointCount;
  final String? cityId;
  final DateTime? updatedAt;
}
