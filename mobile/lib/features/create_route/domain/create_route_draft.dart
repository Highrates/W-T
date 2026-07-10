import '../../../shared/models/event_route_point.dart';
import '../../../shared/models/geo_point.dart';
import 'create_route_join_mode.dart';
import 'create_route_source.dart';

/// Черновик точки при создании маршрута.
class CreateRoutePointDraft {
  const CreateRoutePointDraft({
    required this.title,
    required this.location,
    this.detail,
    this.address,
    this.description,
    this.photoAssets = const [],
    this.cityId,
    this.isStart = false,
    this.isFinish = false,
  });

  final String title;
  final GeoPoint location;
  final String? detail;
  final String? address;

  /// Подробное описание точки (как на странице маршрута).
  final String? description;

  /// Фото точки: asset или локальный путь.
  final List<String> photoAssets;

  /// Город точки (из геокодера / mock-поиска).
  final String? cityId;
  final bool isStart;
  final bool isFinish;

  CreateRoutePointDraft copyWith({
    String? title,
    GeoPoint? location,
    String? detail,
    String? address,
    String? description,
    List<String>? photoAssets,
    String? cityId,
    bool? isStart,
    bool? isFinish,
  }) {
    return CreateRoutePointDraft(
      title: title ?? this.title,
      location: location ?? this.location,
      detail: detail ?? this.detail,
      address: address ?? this.address,
      description: description ?? this.description,
      photoAssets: photoAssets ?? this.photoAssets,
      cityId: cityId ?? this.cityId,
      isStart: isStart ?? this.isStart,
      isFinish: isFinish ?? this.isFinish,
    );
  }

  EventRoutePoint toRoutePoint() {
    return EventRoutePoint(
      title: title,
      location: location,
      address: address,
      detail: detail,
      description: description,
      photoAssets: photoAssets,
    );
  }
}

/// Состояние wizard «Создать маршрут» (до отправки на API).
class CreateRouteDraft {
  const CreateRouteDraft({
    this.source = CreateRouteSource.blank,
    this.sourceEventId,
    this.formatIds = const {},
    this.themeIds = const {},
    this.title = '',
    this.description = '',
    this.cityId = 'sochi',
    this.scheduledAt,
    this.hideExactTime = false,
    this.points = const [],
    this.coverAssets = const [],
    this.joinMode = CreateRouteJoinMode.auto,
    this.maxParticipants = 6,
    this.isOneOnOne = false,
  });

  final CreateRouteSource source;
  final String? sourceEventId;
  final Set<String> formatIds;
  final Set<String> themeIds;
  final String title;
  final String description;
  final String cityId;
  final DateTime? scheduledAt;
  final bool hideExactTime;
  final List<CreateRoutePointDraft> points;
  final List<String> coverAssets;
  final CreateRouteJoinMode joinMode;
  final int? maxParticipants;
  final bool isOneOnOne;

  CreateRouteDraft copyWith({
    CreateRouteSource? source,
    String? sourceEventId,
    Set<String>? formatIds,
    Set<String>? themeIds,
    String? title,
    String? description,
    String? cityId,
    DateTime? scheduledAt,
    bool? hideExactTime,
    List<CreateRoutePointDraft>? points,
    List<String>? coverAssets,
    CreateRouteJoinMode? joinMode,
    int? maxParticipants,
    bool? isOneOnOne,
    bool clearScheduledAt = false,
    bool clearSourceEventId = false,
  }) {
    return CreateRouteDraft(
      source: source ?? this.source,
      sourceEventId:
          clearSourceEventId ? null : (sourceEventId ?? this.sourceEventId),
      formatIds: formatIds ?? this.formatIds,
      themeIds: themeIds ?? this.themeIds,
      title: title ?? this.title,
      description: description ?? this.description,
      cityId: cityId ?? this.cityId,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      hideExactTime: hideExactTime ?? this.hideExactTime,
      points: points ?? this.points,
      coverAssets: coverAssets ?? this.coverAssets,
      joinMode: joinMode ?? this.joinMode,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isOneOnOne: isOneOnOne ?? this.isOneOnOne,
    );
  }

  bool get hasStartPoint => points.any((point) => point.isStart);
  bool get hasFinishPoint => points.any((point) => point.isFinish);

  /// Выбранные «ягоды» ленты: формат + темы в одном наборе.
  Set<String> get hotFilterIds => {...formatIds, ...themeIds};

  CreateRoutePointDraft? get startPoint =>
      points.where((point) => point.isStart).firstOrNull;
}

extension _FirstOrNullDraft<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
