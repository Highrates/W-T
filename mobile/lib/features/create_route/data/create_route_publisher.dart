import '../../../features/shell/data/feed_filter_mock.dart';
import '../../../features/shell/data/location_filter_mock.dart';
import '../../../shared/models/event_card_data.dart';
import '../../../shared/models/event_route_metric.dart';
import '../../../shared/models/event_route_point.dart';
import '../data/create_route_sources_mock.dart';
import '../domain/create_route_draft.dart';
import '../domain/create_route_join_mode.dart';

/// Преобразование черновика wizard в опубликованное событие (mock).
abstract final class CreateRoutePublisher {
  static EventCardData toEventCard({
    required CreateRouteDraft draft,
    required String eventId,
  }) {
    final max = draft.isOneOnOne ? 2 : (draft.maxParticipants ?? 6);
    final pointCount = draft.points.length;
    final tags = _buildTags(draft);

    return EventCardData(
      id: eventId,
      cityId: draft.cityId,
      whenLabel: _formatWhen(draft),
      isWhenHidden: draft.hideExactTime,
      goingLabel: '0/$max идут',
      routeMetric: EventRouteMetric.points,
      routeMetricLabel: '$pointCount ${_pointsLabel(pointCount)}',
      participants: const [],
      coverAssets: List<String>.from(draft.coverAssets),
      organizerId: CreateRouteSourcesMock.currentOrganizerId,
      organizerName: 'Соломон Волков',
      organizerAvatarAsset: 'assets/images/people/04.jpg',
      title: draft.title,
      description: draft.description,
      tags: tags,
      formatIds: draft.formatIds.toList(),
      themeIds: draft.themeIds.toList(),
      isOneOnOne: draft.isOneOnOne,
      ctaLabel: draft.joinMode == CreateRouteJoinMode.approval
          ? 'Отправить заявку'
          : 'Присоединиться!',
    );
  }

  static List<EventRoutePoint> toRoutePoints(CreateRouteDraft draft) {
    return draft.points.map((point) => point.toRoutePoint()).toList();
  }

  static String generateEventId() {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'created_$stamp';
  }

  static List<String> _buildTags(CreateRouteDraft draft) {
    final tags = <String>[];
    final city = LocationFilterMock.cityOptions
        .where((option) => option.id == draft.cityId)
        .firstOrNull;
    if (city != null) tags.add(city.label);

    for (final formatId in draft.formatIds) {
      final format = FeedHotFilterMock.byId(formatId);
      if (format != null) tags.add(format.label);
    }

    for (final themeId in draft.themeIds) {
      final theme = FeedHotFilterMock.byId(themeId);
      if (theme != null) tags.add(theme.label);
    }

    return tags;
  }

  static String _formatWhen(CreateRouteDraft draft) {
    final at = draft.scheduledAt;
    if (at == null) return 'Без даты';
    if (draft.hideExactTime) return 'Сегодня';

    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    return '${at.day}.${at.month.toString().padLeft(2, '0')} $hour:$minute';
  }

  static String _pointsLabel(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'точек';
    return switch (mod10) {
      1 => 'точка',
      2 || 3 || 4 => 'точки',
      _ => 'точек',
    };
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
