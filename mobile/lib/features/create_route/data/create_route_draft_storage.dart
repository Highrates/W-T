import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/create_route_controller.dart';
import 'create_route_draft_codec.dart';

const _draftStorageKey = 'create_route_wizard_draft_v1';

final createRouteDraftStorageProvider = Provider<CreateRouteDraftStorage>(
  (ref) => CreateRouteDraftStorage(),
);

/// Локальное сохранение черновика wizard (до API).
class CreateRouteDraftStorage {
  Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_draftStorageKey);
  }

  Future<void> save(CreateRouteWizardState state) async {
    final prefs = await SharedPreferences.getInstance();
    final json = CreateRouteDraftCodec.encodeWizard(state);
    await prefs.setString(_draftStorageKey, jsonEncode(json));
  }

  Future<CreateRouteWizardState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftStorageKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return CreateRouteDraftCodec.decodeWizard(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftStorageKey);
  }
}
