import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';

/// Открыть «Мою страницу» текущего пользователя.
void openMyProfile(BuildContext context) {
  context.push(AppRoutes.me);
}
