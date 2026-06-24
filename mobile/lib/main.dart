import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/walk_talk_app.dart';
import 'core/map/mapkit_bootstrap.dart';
import 'core/map/mapkit_lifecycle_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MapKitBootstrap.initIfConfigured();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    const MapKitLifecycleHost(
      child: WalkTalkApp(),
    ),
  );
}
