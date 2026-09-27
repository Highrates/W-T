import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../ui/media/cover_image.dart';
import '../../../../ui/navigation/app_menu_sheet.dart';
import '../../application/create_route_controller.dart';
import '../../data/create_route_cover_storage.dart';
import '../../domain/create_route_draft.dart';

/// Шторка обложек события.
Future<void> showCreateRoutePhotosSheet({
  required BuildContext context,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.appColors.background,
    elevation: 0,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(kAppMenuSheetTopRadius),
      ),
    ),
    builder: (context) => const _CreateRoutePhotosSheet(),
  );
}

class _CreateRoutePhotosSheet extends ConsumerStatefulWidget {
  const _CreateRoutePhotosSheet();

  @override
  ConsumerState<_CreateRoutePhotosSheet> createState() =>
      _CreateRoutePhotosSheetState();
}

class _CreateRoutePhotosSheetState
    extends ConsumerState<_CreateRoutePhotosSheet> {
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
        images.map(
          (file) => CreateRouteCoverStorage.persistPickedFile(file.path),
        ),
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
    final colors = context.appColors;
    final draft = ref.watch(createRouteControllerProvider).draft;
    final photos = draft.coverAssets;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.72;
    final controller = ref.read(createRouteControllerProvider.notifier);

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.paddingGlobal,
          AppSpacing.s16,
          AppSpacing.paddingGlobal,
          bottom + AppSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.caption.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Фото',
              style: AppTextStyles.text18_600(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Обложки события — по желанию',
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
            const SizedBox(height: AppSpacing.s16),
            Expanded(
              child: photos.isEmpty
                  ? Center(
                      child: Text(
                        'Пока без фото',
                        style: AppTextStyles.text15_450(color: colors.caption),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.s8,
                        mainAxisSpacing: AppSpacing.s8,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        return _PhotoTile(
                          path: photos[index],
                          onRemove: () => controller.removeCoverAt(index),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.s12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isPicking ? null : _showAddOptions,
                icon: _isPicking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_isPicking ? 'Загрузка…' : 'Добавить фото'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.text,
                  side: BorderSide(
                    color: colors.caption.withValues(alpha: 0.35),
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.text,
                  foregroundColor: colors.background,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Готово',
                  style: AppTextStyles.text14_550(color: colors.background),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.path,
    required this.onRemove,
  });

  final String path;
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
              ref: path,
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

/// Строка «Фото» на compose.
class CreateRoutePhotosEntryRow extends StatelessWidget {
  const CreateRoutePhotosEntryRow({
    super.key,
    required this.draft,
    required this.onTap,
  });

  final CreateRouteDraft draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final count = draft.coverAssets.length;
    final subtitle = count == 0
        ? 'Добавить обложки'
        : count == 1
            ? '1 фото'
            : '$count фото';

    return Material(
      color: colors.secondBackground,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.photo_outlined,
                size: 22,
                color: count > 0 ? colors.blue : colors.caption,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Фото',
                      style: AppTextStyles.text15_450(color: colors.text),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      subtitle,
                      style: AppTextStyles.text13_400(color: colors.caption),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
