import 'package:flutter/foundation.dart';
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';

import 'mapkit_bootstrap.dart';

/// Когда MapKit рендерит: приложение на экране + вкладка «Карта» активна.
abstract final class MapKitVisibility {
  static bool _sdkReady = false;
  static bool _mapkitStarted = false;
  static bool _appForeground = false;
  static bool _mapTabActive = false;

  static void markSdkReady() {
    _sdkReady = true;
    _syncMapkitState();
  }

  static void setAppForeground(bool value) {
    _appForeground = value;
    _syncMapkitState();
  }

  static void setMapTabActive(bool value) {
    _mapTabActive = value;
    _syncMapkitState();
  }

  /// Hot reload / reassemble: пересинхронизировать с текущими флагами.
  static void resync() {
    if (_mapkitStarted) {
      mapkit.onStop();
      _mapkitStarted = false;
    }
    _syncMapkitState();
  }

  static void _syncMapkitState() {
    if (!_sdkReady || !MapKitBootstrap.isReady) return;

    final shouldRun = _appForeground && _mapTabActive;
    if (shouldRun && !_mapkitStarted) {
      _mapkitStarted = true;
      mapkit.onStart();
    } else if (!shouldRun && _mapkitStarted) {
      _mapkitStarted = false;
      mapkit.onStop();
    }
  }

  static void logKeyStatus() {
    if (!kDebugMode || !MapKitBootstrap.isReady) return;
    debugPrint('MapKit: API key loaded (${MapKitBootstrap.apiKeyFingerprint})');
    debugPrint(
      'MapKit: если видна сетка без тайлов — ключ отклонён сервером. '
      'Проверьте тип «MapKit Mobile SDK», bundle id com.walktalk.walkTalk, '
      'активацию (~15 мин) в developer.tech.yandex.ru',
    );
  }
}
