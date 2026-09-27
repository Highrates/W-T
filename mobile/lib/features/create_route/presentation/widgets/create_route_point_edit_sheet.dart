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
import 'create_route_point_role.dart';

/// Шторка описания точки (текст + фото точки).
Future<void> showCreateRoutePointEditSheet({
  required BuildContext context,
  required int pointIndex,
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
    builder: (context) => _CreateRoutePointEditSheet(pointIndex: pointIndex),
  );
}

class _CreateRoutePointEditSheet extends ConsumerStatefulWidget {
  const _CreateRoutePointEditSheet({required this.pointIndex});

  final int pointIndex;

  @override
  ConsumerState<_CreateRoutePointEditSheet> createState() =>
      _CreateRoutePointEditSheetState();
}

class _CreateRoutePointEditSheetState
    extends ConsumerState<_CreateRoutePointEditSheet> {
  final _picker = ImagePicker();
  late final TextEditingController _detail;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    final point =
        ref.read(createRouteControllerProvider).draft.points[widget.pointIndex];
    _detail = TextEditingController(text: point.detail ?? '');
    _description = TextEditingController(text: point.description ?? '');
  }

  @override
  void dispose() {
    _detail.dispose();
    _description.dispose();
    super.dispose();
  }

  CreateRoutePointDraft get _point =>
      ref.read(createRouteControllerProvider).draft.points[widget.pointIndex];

  void _commit(CreateRoutePointDraft point) {
    ref
        .read(createRouteControllerProvider.notifier)
        .updatePointAt(widget.pointIndex, point);
  }

  Future<void> _addPhoto() async {
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
    await ref
        .read(createRouteControllerProvider.notifier)
        .addPointPhotoPaths(widget.pointIndex, paths);
  }

  void _removePhoto(int photoIndex) {
    final point = _point;
    final photos = [...point.photoAssets]..removeAt(photoIndex);
    _commit(point.copyWith(photoAssets: photos));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final draft = ref.watch(createRouteControllerProvider).draft;
    if (widget.pointIndex < 0 || widget.pointIndex >= draft.points.length) {
      return const SizedBox.shrink();
    }
    final point = draft.points[widget.pointIndex];
    final role = point.isStart
        ? CreateRoutePointRole.start
        : point.isFinish
            ? CreateRoutePointRole.finish
            : CreateRoutePointRole.middle;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.paddingGlobal,
        AppSpacing.s16,
        AppSpacing.paddingGlobal,
        bottom + viewInsets + AppSpacing.s16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              createRoutePointRoleLabel(role),
              style: AppTextStyles.text13_400(color: colors.accent),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              point.title,
              style: AppTextStyles.text18_600(color: colors.text),
            ),
            if (point.address != null && point.address!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                point.address!,
                style: AppTextStyles.text13_400(color: colors.caption),
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _detail,
              decoration: const InputDecoration(
                labelText: 'Кратко',
                hintText: 'Например: вход с набережной',
              ),
              onChanged: (value) {
                final current = _point;
                _commit(
                  current.copyWith(
                    detail: value.trim().isEmpty ? null : value,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.s12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Что здесь интересного, где встречаемся…',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
              onChanged: (value) {
                final current = _point;
                _commit(
                  current.copyWith(
                    description: value.trim().isEmpty ? null : value,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Фото точки',
              style: AppTextStyles.text15_450(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s8),
            _PointPhotosGrid(
              photos: point.photoAssets,
              onAdd: _addPhoto,
              onRemove: _removePhoto,
            ),
            const SizedBox(height: AppSpacing.s24),
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

class _PointPhotosGrid extends StatelessWidget {
  const _PointPhotosGrid({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.s8,
        mainAxisSpacing: AppSpacing.s8,
      ),
      itemCount: photos.length + 1,
      itemBuilder: (context, index) {
        if (index == photos.length) {
          return Material(
            color: colors.secondBackground,
            borderRadius: BorderRadius.circular(AppRadius.r8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onAdd,
              child: Center(
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: colors.caption,
                ),
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.r8),
              child: CoverImage(ref: photos[index], fit: BoxFit.cover),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: colors.background.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onRemove(index),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close_rounded, size: 16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
