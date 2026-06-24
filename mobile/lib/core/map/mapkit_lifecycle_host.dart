import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';

import 'map_kit_visibility.dart';
import 'mapkit_bootstrap.dart';

/// Foreground/background приложения для MapKit.
class MapKitLifecycleHost extends StatefulWidget {
  const MapKitLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  State<MapKitLifecycleHost> createState() => _MapKitLifecycleHostState();
}

class _MapKitLifecycleHostState extends State<MapKitLifecycleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MapKitVisibility.setAppForeground(true);
  }

  @override
  void dispose() {
    MapKitVisibility.setAppForeground(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    MapKitVisibility.resync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!MapKitBootstrap.isReady) return;
    switch (state) {
      case AppLifecycleState.resumed:
        MapKitVisibility.setAppForeground(true);
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        MapKitVisibility.setAppForeground(false);
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
