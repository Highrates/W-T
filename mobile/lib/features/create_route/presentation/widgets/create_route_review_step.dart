import 'package:flutter/material.dart';

import '../../../../core/map/map_deferred_host.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../cards/presentation/widgets/walk_card.dart';
import '../../../event/presentation/widgets/event_route_map.dart';
import '../../../event/presentation/widgets/event_route_points_list.dart';
import '../../data/create_route_publisher.dart';
import '../../domain/create_route_draft.dart';

/// Шаг «Проверка»: превью карточки ленты и карта маршрута.
class CreateRouteReviewStep extends StatelessWidget {
  const CreateRouteReviewStep({super.key, required this.draft});

  final CreateRouteDraft draft;

  @override
  Widget build(BuildContext context) {
    final preview = CreateRoutePublisher.toEventCard(
      draft: draft,
      eventId: 'preview',
    );
    final routePoints = CreateRoutePublisher.toRoutePoints(draft);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        WalkCard(data: preview),
        if (routePoints.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s24),
          EventRouteMap(
            points: routePoints,
            deferStrategy: MapDeferStrategy.postFrame,
          ),
          const SizedBox(height: AppSpacing.s24),
          EventRoutePointsList(points: routePoints),
        ],
      ],
    );
  }
}
