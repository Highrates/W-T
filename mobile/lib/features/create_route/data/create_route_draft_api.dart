import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import '../../../core/providers/auth_providers.dart';
import '../application/create_route_controller.dart';
import '../domain/create_route_step.dart';
import 'create_route_draft_codec.dart';

/// Синхронизация wizard-черновика с `GET/PUT/DELETE /drafts/me`.
class CreateRouteDraftApi {
  CreateRouteDraftApi(this._ref);

  final Ref _ref;

  bool get _canSync =>
      ApiConfig.useApi && _ref.read(authSessionProvider).isAuthenticated;

  Future<CreateRouteWizardState?> fetchRemote() async {
    if (!_canSync) return null;

    final json = await _ref.read(apiClientProvider).getJson(
          '/drafts/me',
          auth: true,
        );

    final draftJson = json['draft'];
    if (draftJson == null) return null;
    if (draftJson is! Map<String, dynamic>) return null;

    final stepName = json['step'] as String? ?? CreateRouteStep.compose.name;
    final step = CreateRouteStep.fromStorageName(stepName);
    final draft = CreateRouteDraftCodec.decodeDraft(draftJson);
    if (step == null || draft == null) return null;

    return CreateRouteWizardState(step: step, draft: draft);
  }

  Future<void> upsert(CreateRouteWizardState state) async {
    if (!_canSync) return;

    await _ref.read(apiClientProvider).putJson(
          '/drafts/me',
          auth: true,
          body: {
            'step': state.step.name,
            'draft': CreateRouteDraftCodec.encodeDraft(state.draft),
          },
        );
  }

  Future<void> deleteRemote() async {
    if (!_canSync) return;

    await _ref.read(apiClientProvider).deleteJson(
          '/drafts/me',
          auth: true,
        );
  }
}

final createRouteDraftApiProvider = Provider<CreateRouteDraftApi>(
  (ref) => CreateRouteDraftApi(ref),
);
