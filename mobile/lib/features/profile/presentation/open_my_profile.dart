import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/auth/require_auth.dart';

/// Открыть «Мою страницу» текущего пользователя.
Future<void> openMyProfile(BuildContext context) async {
  if (!await requireAuth(context)) return;
  if (!context.mounted) return;
  context.push(AppRoutes.me);
}
