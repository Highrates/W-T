import 'models/event_participant.dart';

/// Аватар в ленте участников (организатор + принятые).
class GoingAvatarEntry {
  const GoingAvatarEntry({
    required this.userId,
    required this.avatarAsset,
  });

  final String userId;
  final String avatarAsset;
}

List<GoingAvatarEntry> buildGoingAvatarEntries({
  required String organizerId,
  required String organizerAvatarAsset,
  required List<EventParticipant> participants,
}) {
  final seen = <String>{};
  final entries = <GoingAvatarEntry>[];

  void add(String userId, String avatarAsset) {
    if (seen.add(userId)) {
      entries.add(
        GoingAvatarEntry(userId: userId, avatarAsset: avatarAsset),
      );
    }
  }

  add(organizerId, organizerAvatarAsset);
  for (final person in participants) {
    add(person.id, person.avatarAsset);
  }
  return entries;
}
