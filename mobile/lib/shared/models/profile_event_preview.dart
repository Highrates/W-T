/// Краткое превью события на странице профиля.
class ProfileEventPreview {
  const ProfileEventPreview({
    required this.eventId,
    required this.title,
    required this.coverAsset,
    required this.goingLabel,
    this.whenLabel,
    this.isWhenHidden = false,
    this.isPast = false,
  });

  final String eventId;
  final String title;
  final String coverAsset;
  final String? whenLabel;
  final bool isWhenHidden;
  final String goingLabel;
  final bool isPast;
}
