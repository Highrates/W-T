import '../going_avatar_entries.dart';
import 'event_join_status.dart';
import 'event_participant.dart';
import 'event_route_metric.dart';

/// DTO события в ленте и на экране детали (до полноценного domain-слоя).
class EventCardData {
  const EventCardData({
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
    this.cityId = 'sochi',
    this.whenLabel,
    this.isWhenHidden = false,
    this.isOrganizerVerified = false,
    this.ctaLabel = 'Присоединиться!',
    this.joinStatus = EventJoinStatus.canJoin,
    this.tags = const [],
    this.formatIds = const [],
    this.themeIds = const [],
  });

  final String id;
  final String cityId;
  final String? whenLabel;
  final bool isWhenHidden;
  final String goingLabel;
  final EventRouteMetric routeMetric;
  final String routeMetricLabel;
  final List<EventParticipant> participants;
  final List<String> coverAssets;
  final String organizerId;
  final String organizerName;
  final String organizerAvatarAsset;
  final bool isOrganizerVerified;
  final String title;
  final String description;
  final String ctaLabel;
  final EventJoinStatus joinStatus;

  /// Теги формата / тематики (чипы на странице мероприятия).
  final List<String> tags;

  /// Фильтры ленты: format axis.
  final List<String> formatIds;

  /// Фильтры ленты: theme axis.
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

  EventCardData copyWith({
    String? cityId,
    String? whenLabel,
    bool? isWhenHidden,
    String? goingLabel,
    EventRouteMetric? routeMetric,
    String? routeMetricLabel,
    List<EventParticipant>? participants,
    List<String>? coverAssets,
    String? organizerId,
    String? organizerName,
    String? organizerAvatarAsset,
    bool? isOrganizerVerified,
    String? title,
    String? description,
    String? ctaLabel,
    EventJoinStatus? joinStatus,
    List<String>? tags,
    List<String>? formatIds,
    List<String>? themeIds,
  }) {
    return EventCardData(
      id: id,
      cityId: cityId ?? this.cityId,
      whenLabel: whenLabel ?? this.whenLabel,
      isWhenHidden: isWhenHidden ?? this.isWhenHidden,
      goingLabel: goingLabel ?? this.goingLabel,
      routeMetric: routeMetric ?? this.routeMetric,
      routeMetricLabel: routeMetricLabel ?? this.routeMetricLabel,
      participants: participants ?? this.participants,
      coverAssets: coverAssets ?? this.coverAssets,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      organizerAvatarAsset: organizerAvatarAsset ?? this.organizerAvatarAsset,
      isOrganizerVerified: isOrganizerVerified ?? this.isOrganizerVerified,
      title: title ?? this.title,
      description: description ?? this.description,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      joinStatus: joinStatus ?? this.joinStatus,
      tags: tags ?? this.tags,
      formatIds: formatIds ?? this.formatIds,
      themeIds: themeIds ?? this.themeIds,
    );
  }
}
