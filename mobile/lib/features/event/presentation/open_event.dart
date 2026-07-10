import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';

/// Открыть страницу события по [eventId].
void openEvent(BuildContext context, String eventId) {
  context.push(AppRoutes.eventPath(eventId));
}

/// Закрыть экран события: назад по стеку или на главную.
void closeEventScreen(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.shell);
  }
}
