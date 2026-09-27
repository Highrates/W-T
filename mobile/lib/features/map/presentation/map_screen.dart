import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/map/map_deferred_host.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../shared/models/geo_point.dart';
import '../../../ui/map/app_map_pin.dart';
import '../../../ui/map/app_yandex_map.dart';
import '../../event/presentation/open_event.dart';
import '../../shell/application/feed_query_controller.dart';
import '../../shell/application/map_controller.dart';
import '../../shell/presentation/widgets/shell_location_filter_row.dart';

/// Вкладка «Карта»: события рядом (на весь экран, nav поверх).
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsAsync = ref.watch(mapControllerProvider);
    final query = ref.watch(feedQueryControllerProvider);
    final queryController = ref.read(feedQueryControllerProvider.notifier);
    final colors = context.appColors;

    return pinsAsync.when(
      loading: () => ColoredBox(
        color: colors.secondBackground,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ColoredBox(
        color: colors.secondBackground,
        child: Center(child: Text('Карта: $error')),
      ),
      data: (pins) => Stack(
        fit: StackFit.expand,
        children: [
          MapDeferredHost(
            strategy: MapDeferStrategy.tabSwitch,
            placeholder: ColoredBox(color: colors.secondBackground),
            builder: (context) {
              return AppYandexMap(
                pins: [
                  for (final pin in pins)
                    AppMapPin(
                      id: pin.occurrenceId,
                      title: pin.title,
                      location: pin.location,
                      imageAsset: pin.coverAsset,
                      style: AppMapPinStyle.eventPhoto,
                    ),
                ],
                initialCenter: GeoPoint.centroid(pins.map((p) => p.location)) ??
                    const GeoPoint(latitude: 43.5782, longitude: 39.7194),
                onPinTap: (pin) {
                  final id = pin.id;
                  if (id == null) return;
                  openEvent(context, id);
                },
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s8),
                child: ShellLocationFilterRow(
                  style: ShellLocationFilterStyle.chips,
                  location: query.location,
                  onLocationChanged: queryController.setLocation,
                  onFilterTap: () {},
                  filterActive: query.hasActiveFilters,
                  simulatedGlass: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
