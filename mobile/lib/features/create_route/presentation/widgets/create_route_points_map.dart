import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/geo_providers.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/geo_point.dart';
import '../../../../ui/buttons/secondary_button.dart';
import '../../../geo/domain/geo_suggestion.dart';
import '../../application/create_route_controller.dart';
import '../../domain/create_route_draft.dart';
import 'create_route_map_picker_screen.dart';
import 'create_route_point_edit_sheet.dart';
import 'create_route_point_role.dart';

/// Шаг «Точки маршрута»: поиск + список; карта — на весь экран.
class CreateRoutePointsMap extends ConsumerStatefulWidget {
  const CreateRoutePointsMap({super.key, required this.draft});

  final CreateRouteDraft draft;

  @override
  ConsumerState<CreateRoutePointsMap> createState() =>
      _CreateRoutePointsMapState();
}

class _CreateRoutePointsMapState extends ConsumerState<CreateRoutePointsMap> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  var _isSearching = false;
  List<GeoSuggestion> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  GeoPoint? get _searchBias {
    if (widget.draft.points.isNotEmpty) {
      return widget.draft.points.last.location;
    }
    return const GeoPoint(latitude: 43.5855, longitude: 39.7231);
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      if (mounted) setState(() => _results = const []);
      return;
    }

    setState(() => _isSearching = true);
    final geo = ref.read(geoRepositoryProvider);
    final items = await geo.suggest(trimmed, bias: _searchBias);
    if (!mounted) return;
    setState(() {
      _results = items;
      _isSearching = false;
    });
  }

  Future<void> _openMapPicker({
    GeoSuggestion? place,
    CreateRoutePointRole? forcedRole,
  }) {
    final draft = widget.draft;
    final role = forcedRole ??
        (!draft.hasStartPoint
            ? CreateRoutePointRole.start
            : CreateRoutePointRole.middle);
    return openCreateRouteMapPicker(
      context: context,
      ref: ref,
      draft: draft,
      initialPlace: place,
      forcedRole: role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(createRouteControllerProvider.notifier);
    final draft = widget.draft;
    final colors = context.appColors;
    final needsStart = !draft.hasStartPoint;
    final canAddMore = draft.hasStartPoint && !draft.hasFinishPoint;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (needsStart || canAddMore) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск места',
                hintText: 'Парк, адрес, POI…',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s8,
                ),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _runSearch(_searchController.text),
                      ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (query) {
                _runSearch(query);
                FocusManager.instance.primaryFocus?.unfocus();
              },
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          if (needsStart)
            SecondaryButton(
              label: 'Отметить на карте',
              icon: const Icon(Icons.map_outlined),
              expanded: true,
              style: SecondaryButtonStyle.whiteOutlined,
              labelColor: colors.text,
              iconColor: colors.text,
              onPressed: () => _openMapPicker(
                forcedRole: CreateRoutePointRole.start,
              ),
            )
          else if (canAddMore)
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Промеж.',
                    icon: const Icon(Icons.add_location_alt_outlined),
                    expanded: true,
                    style: SecondaryButtonStyle.whiteOutlined,
                    labelColor: colors.text,
                    iconColor: colors.text,
                    onPressed: () => _openMapPicker(
                      forcedRole: CreateRoutePointRole.middle,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: SecondaryButton(
                    label: 'Финиш',
                    icon: const Icon(Icons.flag_outlined),
                    expanded: true,
                    style: SecondaryButtonStyle.whiteOutlined,
                    labelColor: colors.text,
                    iconColor: colors.text,
                    onPressed: () => _openMapPicker(
                      forcedRole: CreateRoutePointRole.finish,
                    ),
                  ),
                ),
              ],
            ),
          if (_results.isNotEmpty && (needsStart || canAddMore)) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Результаты поиска',
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
            const SizedBox(height: AppSpacing.s8),
            ..._results.map(
              (place) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: _SearchResultTile(
                  place: place,
                  onTap: () => _openMapPicker(
                    place: place,
                    forcedRole: needsStart
                        ? CreateRoutePointRole.start
                        : CreateRoutePointRole.middle,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Точки',
            style: AppTextStyles.text15_450(color: colors.text),
          ),
          const SizedBox(height: AppSpacing.s8),
          Expanded(
            child: draft.points.isEmpty
                ? _EmptyPointsHint(colors: colors)
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: draft.points.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s8),
                    itemBuilder: (context, index) {
                      final point = draft.points[index];
                      return _RoutePointCard(
                        point: point,
                        index: index,
                        onEdit: () => showCreateRoutePointEditSheet(
                          context: context,
                          pointIndex: index,
                        ),
                        onDelete: () => controller.removePointAt(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.place,
    required this.onTap,
  });

  final GeoSuggestion place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.secondBackground,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            children: [
              Icon(Icons.place_outlined, size: 20, color: colors.caption),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.text14_550(color: colors.text),
                    ),
                    if (place.subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        place.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.text13_400(color: colors.caption),
                      ),
                    ],
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

class _EmptyPointsHint extends StatelessWidget {
  const _EmptyPointsHint({required this.colors});

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
              Icons.route_outlined,
              size: 40,
              color: colors.caption.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Добавьте точку старта',
              textAlign: TextAlign.center,
              style: AppTextStyles.text15_450(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Найдите место в поиске или отметьте точку на карте',
              textAlign: TextAlign.center,
              style: AppTextStyles.text13_400(color: colors.caption),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePointCard extends StatelessWidget {
  const _RoutePointCard({
    required this.point,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final CreateRoutePointDraft point;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final role = point.isStart
        ? CreateRoutePointRole.start
        : point.isFinish
            ? CreateRoutePointRole.finish
            : CreateRoutePointRole.middle;
    final hasDescription = point.description?.trim().isNotEmpty == true ||
        point.detail?.trim().isNotEmpty == true;

    return Material(
      color: colors.secondBackground,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s12,
            AppSpacing.s8,
            AppSpacing.s4,
            AppSpacing.s8,
          ),
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
                  '${index + 1}',
                  style: AppTextStyles.text13_400(color: colors.text),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      createRoutePointRoleLabel(role),
                      style: AppTextStyles.text13_400(color: colors.accent),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      point.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.text14_550(color: colors.text),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      hasDescription
                          ? (point.detail?.trim().isNotEmpty == true
                              ? point.detail!
                              : point.description!)
                          : 'Добавить описание',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.text13_400(
                        color: hasDescription ? colors.caption : colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
