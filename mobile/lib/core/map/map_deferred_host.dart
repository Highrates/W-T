import 'package:flutter/material.dart';

/// Стратегия отложенного mount Yandex MapKit platform view.
enum MapDeferStrategy {
  /// Сразу (fullscreen sheet после анимации открытия).
  none,

  /// После первого кадра (ListView / event preview).
  postFrame,

  /// После кадра + 80 ms (смена вкладки «Карта»).
  tabSwitch,
}

/// Обёртка: откладывает создание MapKit GL-view до готовности surface.
class MapDeferredHost extends StatefulWidget {
  const MapDeferredHost({
    super.key,
    this.strategy = MapDeferStrategy.postFrame,
    required this.placeholder,
    required this.builder,
  });

  final MapDeferStrategy strategy;
  final Widget placeholder;
  final Widget Function(BuildContext context) builder;

  @override
  State<MapDeferredHost> createState() => _MapDeferredHostState();
}

class _MapDeferredHostState extends State<MapDeferredHost> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.strategy == MapDeferStrategy.none) {
      _ready = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.strategy == MapDeferStrategy.tabSwitch) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
      }
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return widget.placeholder;
    return widget.builder(context);
  }
}
