import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';
import '../../../core/providers/auth_providers.dart';
import '../application/create_route_controller.dart';
import 'create_route_draft_api.dart';
import 'create_route_draft_codec.dart';

const _draftStorageKey = 'create_route_wizard_draft_v1';

final createRouteDraftStorageProvider = Provider<CreateRouteDraftStorage>(
  (ref) => CreateRouteDraftStorage(ref),
);

/// Локальное сохранение + синхронизация с `/drafts/me` в API-режиме.
class CreateRouteDraftStorage {
  CreateRouteDraftStorage(this._ref);

  final Ref _ref;

  CreateRouteDraftApi get _api => _ref.read(createRouteDraftApiProvider);

  bool get _canSync =>
      ApiConfig.useApi && _ref.read(authSessionProvider).isAuthenticated;

  Future<bool> hasDraft() async {
    if (_canSync) {
      try {
        final remote = await _api.fetchRemote();
        if (remote != null) return true;
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_draftStorageKey);
  }

  Future<void> save(CreateRouteWizardState state) async {
    final prefs = await SharedPreferences.getInstance();
    final json = CreateRouteDraftCodec.encodeWizard(state);
    await prefs.setString(_draftStorageKey, jsonEncode(json));

    if (_canSync) {
      try {
        await _api.upsert(state);
      } catch (_) {}
    }
  }

  Future<CreateRouteWizardState?> load() async {
    if (_canSync) {
      try {
        final remote = await _api.fetchRemote();
        if (remote != null) {
          await save(remote);
          return remote;
        }
      } catch (_) {}
    }

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

    if (_canSync) {
      try {
        await _api.deleteRemote();
      } catch (_) {}
    }
  }
}
