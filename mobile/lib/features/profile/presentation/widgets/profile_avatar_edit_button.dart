import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/my_page_provider.dart';
import '../../data/profile_avatar_service.dart';

/// Кнопка смены аватара на «Моя страница».
class ProfileAvatarEditButton extends ConsumerStatefulWidget {
  const ProfileAvatarEditButton({super.key});

  @override
  ConsumerState<ProfileAvatarEditButton> createState() =>
      _ProfileAvatarEditButtonState();
}

class _ProfileAvatarEditButtonState extends ConsumerState<ProfileAvatarEditButton> {
  final _picker = ImagePicker();
  var _uploading = false;

  Future<void> _pickAndUpload() async {
    if (!ApiConfig.useApi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Загрузка аватара доступна в API-режиме')),
      );
      return;
    }

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (image == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await ref.read(profileAvatarServiceProvider).uploadAndPatchAvatar(image.path);
      ref.invalidate(myPageDataProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аватар обновлён')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить аватар: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _uploading ? null : _pickAndUpload,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: _uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
