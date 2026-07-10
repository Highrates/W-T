/// Участник события.
class EventParticipant {
  const EventParticipant({
    required this.id,
    required this.name,
    required this.avatarAsset,
  });

  final String id;
  final String name;
  final String avatarAsset;
}
