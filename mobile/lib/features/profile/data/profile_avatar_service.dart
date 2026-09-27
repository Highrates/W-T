import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import '../../create_route/data/media_upload_service.dart';

/// Presign (avatar) → PATCH /users/me { avatarUrl }.
class ProfileAvatarService {
  ProfileAvatarService(this._ref);

  final Ref _ref;

  Future<String> uploadAndPatchAvatar(String localPath) async {
    if (!ApiConfig.useApi) {
      throw StateError('Avatar upload requires API mode');
    }

    final avatarUrl = await _ref
        .read(mediaUploadServiceProvider)
        .uploadLocalFile(localPath, UploadMediaPurpose.avatar);

    final json = await _ref.read(apiClientProvider).patchJson(
          '/users/me',
          auth: true,
          body: {'avatarUrl': avatarUrl},
        );

    final updated = json['avatarUrl'] as String?;
    return updated ?? avatarUrl;
  }
}

final profileAvatarServiceProvider = Provider<ProfileAvatarService>(
  (ref) => ProfileAvatarService(ref),
);
