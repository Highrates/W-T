/// Заявка участника (ответ GET /occurrences/:id/participations).
class EventParticipation {
  const EventParticipation({
    required this.id,
    required this.userId,
    required this.name,
    required this.status,
    this.avatarAsset,
    this.bio,
    this.isVerified = false,
  });

  final String id;
  final String userId;
  final String name;
  final String? avatarAsset;
  final String? bio;
  final bool isVerified;

  /// `pending` | `accepted`
  final String status;

  bool get isPending => status == 'pending';
}
