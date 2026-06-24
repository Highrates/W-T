import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/geo_point.dart';
import '../../../ui/map/app_map_pin.dart';
import '../../../ui/map/app_yandex_map.dart';
import '../../event/data/mock_event_repository.dart';
import '../../event/presentation/event_screen.dart';
import '../../shell/data/location_filter_mock.dart';
import '../../shell/presentation/widgets/shell_location_filter_row.dart';
import '../data/mock_map_repository.dart';

/// Вкладка «Карта»: события рядом (на весь экран, nav поверх).
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.location,
    required this.onLocationChanged,
    required this.onFilterTap,
    this.filterActive = false,
  });

  final LocationFilterOption location;
  final ValueChanged<LocationFilterOption> onLocationChanged;
  final VoidCallback onFilterTap;
  final bool filterActive;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Platform view создаём после первого кадра — иначе YRTGLView падает в
  /// `createBuffers` при резком mount после смены вкладки.
  bool _platformViewReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // MapKit.onStart + GL-view: пауза после активации вкладки.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() => _platformViewReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pins = mapRepository.getOccurrencePins();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_platformViewReady)
          AppYandexMap(
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
            initialCenter: GeoPoint.centroid(pins.map((p) => p.location)),
            onPinTap: (pin) {
              final id = pin.id;
              if (id == null) return;
              final detail = eventRepository.getDetail(id);
              if (detail == null) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EventScreen(data: detail),
                ),
              );
            },
          )
        else
          const ColoredBox(color: Color(0xFFE8EAED)),
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
                location: widget.location,
                onLocationChanged: widget.onLocationChanged,
                onFilterTap: widget.onFilterTap,
                filterActive: widget.filterActive,
                simulatedGlass: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
