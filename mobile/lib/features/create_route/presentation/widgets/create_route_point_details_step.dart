import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../ui/media/cover_image.dart';
import '../../application/create_route_controller.dart';
import '../../data/create_route_cover_storage.dart';
import '../../domain/create_route_draft.dart';
import 'create_route_point_role.dart';

/// Шаг «Описание точек»: detail, description, фото — как на странице маршрута.
class CreateRoutePointDetailsStep extends ConsumerStatefulWidget {
  const CreateRoutePointDetailsStep({super.key, required this.draft});

  final CreateRouteDraft draft;

  @override
  ConsumerState<CreateRoutePointDetailsStep> createState() =>
      _CreateRoutePointDetailsStepState();
}

class _CreateRoutePointDetailsStepState
    extends ConsumerState<CreateRoutePointDetailsStep> {
  final _picker = ImagePicker();
  int? _expandedIndex;

  CreateRoutePointRole _roleFor(CreateRoutePointDraft point) {
    if (point.isStart) return CreateRoutePointRole.start;
    if (point.isFinish) return CreateRoutePointRole.finish;
    return CreateRoutePointRole.middle;
  }

  void _updatePoint(int index, CreateRoutePointDraft point) {
    ref.read(createRouteControllerProvider.notifier).updatePointAt(index, point);
  }

  Future<void> _addPhoto(int index) async {
    final images = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (images.isEmpty || !mounted) return;

    final paths = await Future.wait(
      images.map((file) => CreateRouteCoverStorage.persistPickedFile(file.path)),
    );
    await ref
        .read(createRouteControllerProvider.notifier)
        .addPointPhotoPaths(index, paths);
  }

  void _removePhoto(int pointIndex, int photoIndex) {
    final point = widget.draft.points[pointIndex];
    final photos = [...point.photoAssets]..removeAt(photoIndex);
    _updatePoint(pointIndex, point.copyWith(photoAssets: photos));
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.draft.points;
    final colors = context.appColors;

    if (points.isEmpty) {
      return Center(
        child: Text(
          'Сначала добавьте точки на предыдущем шаге',
          style: AppTextStyles.text15_450(color: colors.caption),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: points.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) {
        final point = points[index];
        final expanded = _expandedIndex == index;

        return _PointDetailCard(
          key: ValueKey('point-$index-${point.title}'),
          index: index,
          point: point,
          roleLabel: createRoutePointRoleLabel(_roleFor(point)),
          expanded: expanded,
          onToggle: () => setState(
            () => _expandedIndex = expanded ? null : index,
          ),
          onChanged: (updated) => _updatePoint(index, updated),
          onAddPhoto: () => _addPhoto(index),
          onRemovePhoto: (photoIndex) => _removePhoto(index, photoIndex),
        );
      },
    );
  }
}

class _PointDetailCard extends StatefulWidget {
  const _PointDetailCard({
    super.key,
    required this.index,
    required this.point,
    required this.roleLabel,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final int index;
  final CreateRoutePointDraft point;
  final String roleLabel;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<CreateRoutePointDraft> onChanged;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;

  @override
  State<_PointDetailCard> createState() => _PointDetailCardState();
}

class _PointDetailCardState extends State<_PointDetailCard> {
  late final TextEditingController _detailController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _detailController = TextEditingController(text: widget.point.detail ?? '');
    _descriptionController =
        TextEditingController(text: widget.point.description ?? '');
  }

  @override
  void didUpdateWidget(covariant _PointDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.point.detail != widget.point.detail &&
        _detailController.text != (widget.point.detail ?? '')) {
      _detailController.text = widget.point.detail ?? '';
    }
    if (oldWidget.point.description != widget.point.description &&
        _descriptionController.text != (widget.point.description ?? '')) {
      _descriptionController.text = widget.point.description ?? '';
    }
  }

  @override
  void dispose() {
    _detailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final point = widget.point;

    return Material(
      color: colors.secondBackground,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.index + 1}',
                      style: AppTextStyles.text13_400(color: colors.text),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.roleLabel,
                          style: AppTextStyles.text13_400(color: colors.accent),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          point.title,
                          maxLines: widget.expanded ? null : 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.text15_450(color: colors.text),
                        ),
                        if (point.address != null &&
                            point.address!.isNotEmpty &&
                            !widget.expanded) ...[
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            point.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTextStyles.text13_400(color: colors.caption),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    widget.expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.caption,
                  ),
                ],
              ),
            ),
          ),
          if (widget.expanded) ...[
            Divider(
              height: 1,
              color: colors.caption.withValues(alpha: 0.2),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Кратко',
                      hintText: 'Например: вход с набережной',
                    ),
                    controller: _detailController,
                    onChanged: (value) => widget.onChanged(
                      point.copyWith(detail: value.trim().isEmpty ? null : value),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      hintText: 'Что здесь интересного, где встречаемся…',
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 6,
                    controller: _descriptionController,
                    onChanged: (value) => widget.onChanged(
                      point.copyWith(
                        description: value.trim().isEmpty ? null : value,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'Фото точки',
                    style: AppTextStyles.text15_450(color: colors.text),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  _PointPhotosGrid(
                    photos: point.photoAssets,
                    onAdd: widget.onAddPhoto,
                    onRemove: widget.onRemovePhoto,
                  ),
                ],
              ),
            ),
          ],
        ],
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
            color: colors.background,
            borderRadius: BorderRadius.circular(AppRadius.r8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onAdd,
              child: Center(
                child: Icon(Icons.add_photo_alternate_outlined,
                    color: colors.caption),
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
