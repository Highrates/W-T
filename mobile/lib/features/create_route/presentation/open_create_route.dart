import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/auth/require_auth.dart';

/// Открывает wizard создания маршрута.
Future<void> openCreateRoute(BuildContext context) async {
  if (!await requireAuth(context)) return;
  if (!context.mounted) return;
  context.push(AppRoutes.createRoute);
}

/// Переход на экран события после публикации.
void openPublishedEvent(BuildContext context, String eventId) {
  context.replace(AppRoutes.publishedEventPath(eventId));
}
