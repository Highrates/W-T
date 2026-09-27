import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../../features/auth/presentation/open_auth.dart';
import '../providers/auth_providers.dart';

/// В API-режиме открывает экран входа, если сессии нет.
Future<bool> requireAuth(BuildContext context) async {
  if (!ApiConfig.useApi) return true;

  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(authSessionProvider).isAuthenticated) {
    return true;
  }

  return openAuth(context);
}
