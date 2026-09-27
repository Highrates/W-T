import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';

/// Открыть OTP-авторизацию. Возвращает `true`, если вход выполнен.
Future<bool> openAuth(BuildContext context) async {
  final result = await context.push<bool>(AppRoutes.auth);
  return result == true;
}
