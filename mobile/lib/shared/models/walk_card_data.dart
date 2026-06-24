import '../going_avatar_entries.dart';
import 'walk_card_join_status.dart';
import 'walk_card_participant.dart';
import 'walk_card_route_metric.dart';

/// Карточка события в ленте «Карточки».
class WalkCardData {
  const WalkCardData({
    required this.id,
    required this.goingLabel,
    required this.routeMetric,
    required this.routeMetricLabel,
    required this.participants,
    required this.coverAssets,
    required this.organizerId,
    required this.organizerName,
    required this.organizerAvatarAsset,
    required this.title,
    required this.description,
    this.whenLabel,
    this.isWhenHidden = false,
    this.isOrganizerVerified = false,
    this.ctaLabel = 'Присоединиться!',
    this.joinStatus = WalkCardJoinStatus.canJoin,
    this.tags = const [],
    this.formatIds = const [],
    this.themeIds = const [],
  });

  final String id;
  final String? whenLabel;
  final bool isWhenHidden;
  final String goingLabel;
  final WalkCardRouteMetric routeMetric;
  final String routeMetricLabel;
  final List<WalkCardParticipant> participants;
  final List<String> coverAssets;
  final String organizerId;
  final String organizerName;
  final String organizerAvatarAsset;
  final bool isOrganizerVerified;
  final String title;
  final String description;
  final String ctaLabel;
  final WalkCardJoinStatus joinStatus;

  /// Теги формата / тематики (чипы на странице мероприятия).
  final List<String> tags;

  /// Фильтры ленты: [FeedHotFilterMock.formatFilters].
  final List<String> formatIds;

  /// Фильтры ленты: [FeedHotFilterMock.themeFilters].
  final List<String> themeIds;

  bool get hasCoverPhotos => coverAssets.isNotEmpty;

  String? get primaryCoverAsset =>
      coverAssets.isNotEmpty ? coverAssets.first : null;

  List<String> get participantAvatarAssets => [
        for (final p in participants) p.avatarAsset,
      ];

  List<GoingAvatarEntry> get goingAvatarEntries => buildGoingAvatarEntries(
        organizerId: organizerId,
        organizerAvatarAsset: organizerAvatarAsset,
        participants: participants,
      );
}
