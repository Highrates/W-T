import '../../../shared/models/geo_point.dart';
import '../domain/create_route_draft.dart';
import '../domain/create_route_join_mode.dart';
import '../domain/create_route_source.dart';
import '../domain/create_route_step.dart';
import '../application/create_route_controller.dart';

/// JSON-сериализация черновика wizard (local storage).
abstract final class CreateRouteDraftCodec {
  static Map<String, dynamic> encodeWizard(CreateRouteWizardState state) {
    return {
      'step': state.step.name,
      'draft': encodeDraft(state.draft),
    };
  }

  static CreateRouteWizardState? decodeWizard(Map<String, dynamic> json) {
    final stepName = json['step'] as String?;
    final draftJson = json['draft'];
    if (stepName == null || draftJson is! Map<String, dynamic>) return null;

    final step = CreateRouteStep.values
        .where((value) => value.name == stepName)
        .firstOrNull;
    final draft = decodeDraft(draftJson);
    if (step == null || draft == null) return null;

    return CreateRouteWizardState(step: step, draft: draft);
  }

  static Map<String, dynamic> encodeDraft(CreateRouteDraft draft) {
    return {
      'source': draft.source.name,
      'sourceEventId': draft.sourceEventId,
      'formatIds': draft.formatIds.toList(),
      'themeIds': draft.themeIds.toList(),
      'title': draft.title,
      'description': draft.description,
      'cityId': draft.cityId,
      'scheduledAt': draft.scheduledAt?.toIso8601String(),
      'hideExactTime': draft.hideExactTime,
      'points': draft.points.map(encodePoint).toList(),
      'coverAssets': draft.coverAssets,
      'joinMode': draft.joinMode.name,
      'maxParticipants': draft.maxParticipants,
      'isOneOnOne': draft.isOneOnOne,
    };
  }

  static CreateRouteDraft? decodeDraft(Map<String, dynamic> json) {
    final source = CreateRouteSource.values
        .where((value) => value.name == json['source'])
        .firstOrNull;
    final joinMode = CreateRouteJoinMode.values
        .where((value) => value.name == json['joinMode'])
        .firstOrNull;
    if (source == null || joinMode == null) return null;

    final pointsJson = json['points'];
    final points = pointsJson is List
        ? pointsJson
            .whereType<Map<String, dynamic>>()
            .map(decodePoint)
            .whereType<CreateRoutePointDraft>()
            .toList()
        : const <CreateRoutePointDraft>[];

    final themesJson = json['themeIds'];
    final themeIds = themesJson is List
        ? themesJson.whereType<String>().toSet()
        : <String>{};

    final coversJson = json['coverAssets'];
    final coverAssets = coversJson is List
        ? coversJson.whereType<String>().toList()
        : const <String>[];

    final scheduledRaw = json['scheduledAt'] as String?;

    final formatsJson = json['formatIds'];
    final formatIds = formatsJson is List
        ? formatsJson.whereType<String>().toSet()
        : json['formatId'] is String
            ? {json['formatId'] as String}
            : <String>{};

    return CreateRouteDraft(
      source: source,
      sourceEventId: json['sourceEventId'] as String?,
      formatIds: formatIds,
      themeIds: themeIds,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cityId: json['cityId'] as String? ?? 'sochi',
      scheduledAt:
          scheduledRaw != null ? DateTime.tryParse(scheduledRaw) : null,
      hideExactTime: json['hideExactTime'] as bool? ?? false,
      points: points,
      coverAssets: coverAssets,
      joinMode: joinMode,
      maxParticipants: json['maxParticipants'] as int? ?? 6,
      isOneOnOne: json['isOneOnOne'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> encodePoint(CreateRoutePointDraft point) {
    return {
      'title': point.title,
      'location': {
        'latitude': point.location.latitude,
        'longitude': point.location.longitude,
      },
      'detail': point.detail,
      'address': point.address,
      'description': point.description,
      'photoAssets': point.photoAssets,
      'cityId': point.cityId,
      'isStart': point.isStart,
      'isFinish': point.isFinish,
    };
  }

  static CreateRoutePointDraft? decodePoint(Map<String, dynamic> json) {
    final locationJson = json['location'];
    if (locationJson is! Map<String, dynamic>) return null;
    final lat = locationJson['latitude'];
    final lng = locationJson['longitude'];
    if (lat is! num || lng is! num) return null;

    return CreateRoutePointDraft(
      title: json['title'] as String? ?? '',
      location: GeoPoint(latitude: lat.toDouble(), longitude: lng.toDouble()),
      detail: json['detail'] as String?,
      address: json['address'] as String?,
      description: json['description'] as String?,
      photoAssets: json['photoAssets'] is List
          ? (json['photoAssets'] as List).whereType<String>().toList()
          : const [],
      cityId: json['cityId'] as String?,
      isStart: json['isStart'] as bool? ?? false,
      isFinish: json['isFinish'] as bool? ?? false,
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
