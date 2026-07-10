import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';

/// Открывает wizard создания маршрута.
void openCreateRoute(BuildContext context) {
  context.push(AppRoutes.createRoute);
}

/// Переход на экран события после публикации.
void openPublishedEvent(BuildContext context, String eventId) {
  context.replace(AppRoutes.publishedEventPath(eventId));
}
