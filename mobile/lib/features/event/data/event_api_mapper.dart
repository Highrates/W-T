import '../../../shared/models/event_card_data.dart';
import '../../../shared/models/event_detail_data.dart';
import '../../../shared/models/event_join_status.dart';
import '../../../shared/models/event_participant.dart';
import '../../../shared/models/event_route_metric.dart';
import '../../../shared/models/event_route_point.dart';
import '../../../shared/models/geo_point.dart';
import '../../../shared/models/map_occurrence_pin.dart';
import '../../../shared/models/profile_event_preview.dart';
import '../../../shared/models/user_profile.dart';

EventJoinStatus parseJoinStatus(String? raw) {
  switch (raw) {
    case 'pending':
      return EventJoinStatus.pending;
    case 'approved':
      return EventJoinStatus.approved;
    case 'full':
      return EventJoinStatus.full;
    default:
      return EventJoinStatus.canJoin;
  }
}

EventCardData eventCardFromJson(Map<String, dynamic> json) {
  final organizer = json['organizer'];
  final organizerMap =
      organizer is Map<String, dynamic> ? organizer : const <String, dynamic>{};

  final coverUrls = json['coverUrls'];
  final coverAssets = coverUrls is List
      ? coverUrls.whereType<String>().toList()
      : const <String>[];

  final participantsJson = json['participants'];
  final participants = participantsJson is List
      ? [
          for (final item in participantsJson)
            if (item is Map<String, dynamic>) participantFromJson(item),
        ]
      : const <EventParticipant>[];

  final formatIds = _stringList(json['formatIds']);
  final themeIds = _stringList(json['themeIds']);
  final tags = _stringList(json['tags']);

  final joinMode = json['joinMode'] as String?;
  final ctaLabel = json['ctaLabel'] as String? ??
      (joinMode == 'APPROVAL' || joinMode == 'approval'
          ? 'Отправить заявку'
          : 'Присоединиться!');

  return EventCardData(
    id: json['id'] as String,
    cityId: json['cityId'] as String? ?? 'sochi',
    whenLabel: json['whenLabel'] as String?,
    isWhenHidden: json['isWhenHidden'] as bool? ?? false,
    goingLabel: json['goingLabel'] as String? ?? '',
    routeMetric: EventRouteMetric.points,
    routeMetricLabel: json['routeMetricLabel'] as String? ?? '',
    participants: participants,
    coverAssets: coverAssets,
    organizerId: organizerMap['id'] as String? ?? '',
    organizerName: organizerMap['name'] as String? ?? 'Организатор',
    organizerAvatarAsset: _avatarRef(organizerMap['avatarUrl']),
    isOrganizerVerified: organizerMap['isVerified'] as bool? ?? false,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    ctaLabel: ctaLabel,
    joinStatus: parseJoinStatus(json['joinStatus'] as String?),
    tags: tags,
    formatIds: formatIds,
    themeIds: themeIds,
    isOneOnOne: json['isOneOnOne'] as bool? ?? false,
  );
}

EventParticipant participantFromJson(Map<String, dynamic> json) {
  return EventParticipant(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    avatarAsset: _avatarRef(json['avatarUrl']),
  );
}

EventDetailData eventDetailFromJson(Map<String, dynamic> json) {
  final eventJson = json['event'];
  final pointsJson = json['points'];

  return EventDetailData(
    event: eventJson is Map<String, dynamic>
        ? eventCardFromJson(eventJson)
        : eventCardFromJson(json),
    routePoints: pointsJson is List
        ? [
            for (final item in pointsJson)
              if (item is Map<String, dynamic>) routePointFromJson(item),
          ]
        : const [],
  );
}

EventRoutePoint routePointFromJson(Map<String, dynamic> json) {
  final lat = (json['latitude'] as num?)?.toDouble();
  final lng = (json['longitude'] as num?)?.toDouble();

  final photoUrls = json['photoUrls'];
  final photoAssets = photoUrls is List
      ? photoUrls.whereType<String>().toList()
      : const <String>[];

  return EventRoutePoint(
    title: json['title'] as String? ?? '',
    location: GeoPoint(
      latitude: lat ?? 0,
      longitude: lng ?? 0,
    ),
    address: json['address'] as String?,
    detail: json['detail'] as String?,
    description: json['description'] as String?,
    photoAssets: photoAssets,
    poiId: json['poiId'] as String?,
  );
}

MapOccurrencePin mapPinFromJson(Map<String, dynamic> json) {
  return MapOccurrencePin(
    occurrenceId: json['id'] as String,
    title: json['title'] as String? ?? '',
    location: GeoPoint(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    ),
    coverAsset: _avatarRef(json['coverUrl']),
    subtitle: json['subtitle'] as String?,
  );
}

UserProfile userProfileFromJson(Map<String, dynamic> json) {
  final city = json['city'];
  final cityMap = city is Map<String, dynamic> ? city : null;

  final interestTags = _stringList(json['interestTags']);
  final interestFilterIds = _stringList(json['interestFilterIds']);

  final upcomingJson = json['upcomingEvents'];
  final upcoming = upcomingJson is List
      ? [
          for (final item in upcomingJson)
            if (item is Map<String, dynamic>) profileEventFromJson(item),
        ]
      : const <ProfileEventPreview>[];

  final pastJson = json['pastEvents'];
  final past = pastJson is List
      ? [
          for (final item in pastJson)
            if (item is Map<String, dynamic>) profileEventFromJson(item),
        ]
      : null;

  final avatarUrl = json['avatarUrl'] as String?;
  final avatarRef = _avatarRef(avatarUrl);

  final phoneVerified = json['phoneVerified'] as bool? ?? false;
  final emailVerified = json['emailVerified'] as bool? ?? false;

  return UserProfile(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Пользователь',
    avatarAsset: avatarRef,
    photoAssets: avatarUrl != null && avatarUrl.isNotEmpty ? [avatarRef] : [],
    bio: json['bio'] as String?,
    city: cityMap?['name'] as String?,
    isVerified:
        json['isVerified'] as bool? ?? (phoneVerified || emailVerified),
    isOrganizer: json['isOrganizer'] as bool? ?? upcoming.isNotEmpty,
    interestTags: interestTags.isNotEmpty
        ? interestTags
        : interestFilterIds,
    upcomingEvents: upcoming,
    pastEvents: past,
  );
}

ProfileEventPreview profileEventFromJson(Map<String, dynamic> json) {
  return ProfileEventPreview(
    eventId: json['eventId'] as String? ?? json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    coverAsset: _avatarRef(json['coverUrl'] ?? json['coverAsset']),
    whenLabel: json['whenLabel'] as String?,
    isWhenHidden: json['isWhenHidden'] as bool? ?? false,
    goingLabel: json['goingLabel'] as String? ?? '',
    isPast: json['isPast'] as bool? ?? false,
  );
}

UserProfile peopleItemToProfile(Map<String, dynamic> json) {
  final avatarUrl = json['avatarUrl'] as String?;
  final avatarRef = _avatarRef(avatarUrl);
  final interestTags = _stringList(json['interestTags']);

  return UserProfile(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Пользователь',
    avatarAsset: avatarRef,
    photoAssets: avatarUrl != null && avatarUrl.isNotEmpty ? [avatarRef] : [],
    bio: json['bio'] as String?,
    city: json['city'] is Map<String, dynamic>
        ? (json['city'] as Map<String, dynamic>)['name'] as String?
        : null,
    isVerified: json['isVerified'] as bool? ?? false,
    isOrganizer: json['isOrganizer'] as bool? ?? true,
    interestTags: interestTags,
    upcomingEvents: const [],
    pastEvents: const [],
  );
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

String _avatarRef(Object? url) {
  final raw = url as String?;
  if (raw == null || raw.isEmpty) {
    return 'assets/images/people/04.jpg';
  }
  return raw;
}
