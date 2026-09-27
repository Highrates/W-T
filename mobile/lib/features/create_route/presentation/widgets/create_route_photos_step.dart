import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../ui/buttons/secondary_button.dart';
import '../../../../ui/media/cover_image.dart';
import '../../application/create_route_controller.dart';
import '../../data/create_route_cover_storage.dart';
import '../../domain/create_route_draft.dart';

/// Шаг «Фото»: выбор обложек с телефона (галерея / камера).
class CreateRoutePhotosStep extends ConsumerStatefulWidget {
  const CreateRoutePhotosStep({super.key, required this.draft});

  final CreateRouteDraft draft;

  @override
  ConsumerState<CreateRoutePhotosStep> createState() =>
      _CreateRoutePhotosStepState();
}

class _CreateRoutePhotosStepState extends ConsumerState<CreateRoutePhotosStep> {
  final _picker = ImagePicker();
  var _isPicking = false;

  Future<void> _pickFromGallery() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (images.isEmpty || !mounted) return;

      final paths = await Future.wait(
        images.map((file) => CreateRouteCoverStorage.persistPickedFile(file.path)),
      );
      await ref.read(createRouteControllerProvider.notifier).addCoverPaths(paths);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickFromCamera() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (photo == null || !mounted) return;

      final path = await CreateRouteCoverStorage.persistPickedFile(photo.path);
      await ref.read(createRouteControllerProvider.notifier).addCoverPaths([path]);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _showAddOptions() async {
    if (_isPicking) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Галерея'),
                subtitle: const Text('Можно выбрать несколько фото'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Камера'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
          ),
        );
      },
    );

    if (!mounted || source == null) return;
    if (source == ImageSource.gallery) {
      await _pickFromGallery();
    } else {
      await _pickFromCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(createRouteControllerProvider.notifier);
    final photos = widget.draft.coverAssets;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SecondaryButton(
          label: _isPicking ? 'Загрузка…' : 'Добавить фото',
          icon: const Icon(Icons.add_photo_alternate_outlined),
          expanded: true,
          isLoading: _isPicking,
          onPressed: _isPicking ? null : _showAddOptions,
        ),
        const SizedBox(height: AppSpacing.s16),
        Expanded(
          child: photos.isEmpty
              ? _EmptyPhotosHint(colors: colors)
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.s8,
                    mainAxisSpacing: AppSpacing.s8,
                  ),
                  itemCount: photos.length + 1,
                  itemBuilder: (context, index) {
                    if (index == photos.length) {
                      return _AddPhotoTile(
                        onTap: _isPicking ? null : _showAddOptions,
                      );
                    }

                    return _PhotoTile(
                      ref: photos[index],
                      onRemove: () => controller.removeCoverAt(index),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyPhotosHint extends StatelessWidget {
  const _EmptyPhotosHint({required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_outlined,
              size: 40,
              color: colors.caption.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Фото необязательны',
              textAlign: TextAlign.center,
              style: AppTextStyles.text15_450(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Добавьте обложки из галереи или с камеры — шаг можно пропустить',
              textAlign: TextAlign.center,
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.secondBackground,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 28, color: colors.caption),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Ещё фото',
                style: AppTextStyles.text13_400(color: colors.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.ref,
    required this.onRemove,
  });

  final String ref;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(
          color: colors.caption.withValues(alpha: 0.25),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r12 - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CoverImage(
              ref: ref,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: colors.secondBackground,
                child: Icon(Icons.broken_image_outlined, color: colors.caption),
              ),
            ),
            Positioned(
              top: AppSpacing.s4,
              right: AppSpacing.s4,
              child: Material(
                color: colors.background.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.s4),
                    child: Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
