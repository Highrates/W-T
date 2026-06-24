import 'dart:ffi';

import 'package:yandex_maps_mapkit_lite/init.dart' as mapkit_init;
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';
// ignore: implementation_imports
import 'package:yandex_maps_mapkit_lite/src/bindings/common/library.dart';

import '../config/yandex_config.dart';
import 'map_kit_visibility.dart';

final bool Function() _nativeMapkitIsInitialized = library
    .lookup<NativeFunction<Bool Function()>>('yandex_maps_flutter_is_init')
    .asFunction(isLeaf: true);

/// Инициализация MapKit (один раз при старте приложения).
abstract final class MapKitBootstrap {
  static bool _initialized = false;

  static bool get isReady => _initialized;

  /// Маскированный отпечаток ключа для debug-логов.
  static String get apiKeyFingerprint {
    final key = YandexConfig.mapkitApiKey;
    if (key.length < 8) return 'missing';
    return '${key.substring(0, 4)}…${key.substring(key.length - 4)}';
  }

  static Future<void> initIfConfigured() async {
    if (!YandexConfig.hasMapkitKey) return;
    if (_initialized) return;

    // Hot restart: нативный MapKit жив, Dart static сброшен — старый GL
    // поток ещё рисует, пока не вызовем onStop.
    final hotRestart = _nativeMapkitIsInitialized();

    await mapkit_init.initMapkit(
      apiKey: YandexConfig.mapkitApiKey,
      locale: 'ru_RU',
    );

    if (hotRestart) {
      mapkit.onStop();
      await Future<void>.delayed(const Duration(milliseconds: 32));
    }

    _initialized = true;
    MapKitVisibility.markSdkReady();
    MapKitVisibility.logKeyStatus();
  }
}
