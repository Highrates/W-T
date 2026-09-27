import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/map/map_deferred_host.dart';
import '../../../../core/providers/geo_providers.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/models/geo_point.dart';
import '../../../../ui/buttons/primary_button_black.dart';
import '../../../../ui/map/app_map_pin.dart';
import '../../../../ui/map/app_yandex_map.dart';
import '../../../geo/domain/geo_suggestion.dart';
import '../../application/create_route_controller.dart';
import '../../data/create_route_geo.dart';
import '../../domain/create_route_draft.dart';
import 'create_route_point_role.dart';

/// Полноэкранный выбор точки на карте (поиск или «Отметить на карте»).
Future<void> openCreateRouteMapPicker({
  required BuildContext context,
  required WidgetRef ref,
  required CreateRouteDraft draft,
  GeoSuggestion? initialPlace,
  CreateRoutePointRole? forcedRole,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => CreateRouteMapPickerScreen(
        draft: draft,
        initialPlace: initialPlace,
        forcedRole: forcedRole,
      ),
    ),
  );
}

class CreateRouteMapPickerScreen extends ConsumerStatefulWidget {
  const CreateRouteMapPickerScreen({
    super.key,
    required this.draft,
    this.initialPlace,
    this.forcedRole,
  });

  final CreateRouteDraft draft;
  final GeoSuggestion? initialPlace;
  final CreateRoutePointRole? forcedRole;

  @override
  ConsumerState<CreateRouteMapPickerScreen> createState() =>
      _CreateRouteMapPickerScreenState();
}

class _CreateRouteMapPickerScreenState
    extends ConsumerState<CreateRouteMapPickerScreen> {
  GeoPoint? _draftPin;
  GeoSuggestion? _draftPreview;
  var _isResolvingLocation = false;
  late CreateRoutePointRole _role;

  @override
  void initState() {
    super.initState();
    _role = widget.forcedRole ?? defaultCreateRoutePointRole(widget.draft);
    final initial = widget.initialPlace;
    if (initial != null) {
      _draftPin = initial.location;
      _draftPreview = initial;
    }
  }

  GeoPoint? get _mapCenter {
    if (_draftPin != null) return _draftPin;
    if (widget.draft.points.isNotEmpty) {
      return widget.draft.points.last.location;
    }
    return const GeoPoint(latitude: 43.5855, longitude: 39.7231);
  }

  Future<void> _resolveLocation(GeoPoint point) async {
    setState(() {
      _draftPin = point;
      _isResolvingLocation = true;
      _draftPreview = null;
    });

    final geo = ref.read(geoRepositoryProvider);
    final resolved = await geo.reverseGeocode(point);
    if (!mounted) return;

    setState(() {
      _draftPreview = resolved;
      _isResolvingLocation = false;
    });
  }

  Future<void> _onMapTap(GeoPoint point) async {
    await _resolveLocation(point);
  }

  Future<void> _onPinDragEnd(AppMapPin pin, GeoPoint location) async {
    if (pin.id == '__draft__') {
      await _resolveLocation(location);
    }
  }

  void _addPoint() {
    final preview = _draftPreview;
    if (preview == null || _draftPin == null) return;

    final cityId = preview.cityId?.isNotEmpty == true
        ? preview.cityId!
        : CreateRouteGeo.resolveCityId(preview.location);

    ref.read(createRouteControllerProvider.notifier).addPoint(
          CreateRoutePointDraft(
            title: preview.title,
            location: preview.location,
            address: preview.subtitle,
            cityId: cityId,
            isStart: _role == CreateRoutePointRole.start,
            isFinish: _role == CreateRoutePointRole.finish,
          ),
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final draft = widget.draft;
    final located = draft.points.map((point) => point.location).toList();
    final canAdd = _draftPreview != null && !_isResolvingLocation;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MapDeferredHost(
            strategy: MapDeferStrategy.none,
            placeholder: ColoredBox(
              color: colors.secondBackground,
              child: Center(
                child: Text(
                  'Загрузка карты…',
                  style: AppTextStyles.text13_400(color: colors.caption),
                ),
              ),
            ),
            builder: (context) {
              return AppYandexMap(
                preserveCameraOnUpdate: true,
                showRoutePolyline: draft.points.length >= 2,
                largeRouteMarkers: true,
                draftPin: _draftPin,
                onMapTap: _isResolvingLocation ? null : _onMapTap,
                onPinDragEnd: _onPinDragEnd,
                pins: [
                  for (var i = 0; i < draft.points.length; i++)
                    AppMapPin(
                      id: '${i + 1}',
                      title: draft.points[i].title,
                      location: draft.points[i].location,
                      style: AppMapPinStyle.routeWaypoint,
                      waypointIndex: i + 1,
                      draggable: false,
                    ),
                ],
                initialCenter: _draftPin ??
                    GeoPoint.centroid(located) ??
                    _mapCenter,
                initialZoom: _draftPin != null
                    ? 15
                    : GeoPoint.zoomForSpread(located, fallback: 13),
              );
            },
          ),
          if (_isResolvingLocation)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.background.withValues(alpha: 0.2),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: colors.background.withValues(alpha: 0.92),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.s8),
                      child: Icon(Icons.close_rounded, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_draftPin == null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 56),
                  child: Material(
                    color: colors.background.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                        vertical: AppSpacing.s8,
                      ),
                      child: Text(
                        'Нажмите на карту, чтобы поставить метку',
                        style: AppTextStyles.text13_400(color: colors.caption),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomPanel(
              role: _role,
              onRoleChanged: (role) => setState(() => _role = role),
              showRolePicker: widget.forcedRole == null,
              title: _draftPreview?.title,
              subtitle: _draftPreview?.subtitle,
              isLoading: _isResolvingLocation,
              hasPin: _draftPin != null,
              canAdd: canAdd,
              onAdd: _addPoint,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.role,
    required this.onRoleChanged,
    required this.showRolePicker,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.hasPin,
    required this.canAdd,
    required this.onAdd,
  });

  final CreateRoutePointRole role;
  final ValueChanged<CreateRoutePointRole> onRoleChanged;
  final bool showRolePicker;
  final String? title;
  final String? subtitle;
  final bool isLoading;
  final bool hasPin;
  final bool canAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: colors.background,
      elevation: 12,
      shadowColor: colors.text.withValues(alpha: 0.12),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.paddingGlobal,
          AppSpacing.s16,
          AppSpacing.paddingGlobal,
          bottomInset + AppSpacing.s16,
        ),
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
              isLoading
                  ? 'Определяем адрес…'
                  : title ?? (hasPin ? '…' : 'Метка не выбрана'),
              style: AppTextStyles.text18_600(color: colors.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                subtitle!,
                style: AppTextStyles.text13_400(color: colors.caption),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (showRolePicker) ...[
              const SizedBox(height: AppSpacing.s16),
              _RolePicker(role: role, onChanged: onRoleChanged),
            ],
            const SizedBox(height: AppSpacing.s16),
            PrimaryButtonBlack(
              label: createRoutePointAddLabel(role),
              onPressed: canAdd ? onAdd : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({
    required this.role,
    required this.onChanged,
  });

  final CreateRoutePointRole role;
  final ValueChanged<CreateRoutePointRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in CreateRoutePointRole.values) ...[
          Expanded(
            child: _RoleChip(
              label: createRoutePointRoleShortLabel(option),
              selected: role == option,
              onTap: () => onChanged(option),
            ),
          ),
          if (option != CreateRoutePointRole.values.last)
            const SizedBox(width: AppSpacing.s8),
        ],
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: selected ? colors.text : colors.secondBackground,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.text13_400(
                color: selected ? colors.background : colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
