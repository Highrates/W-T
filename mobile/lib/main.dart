import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/walk_talk_app.dart';
import 'core/map/mapkit_bootstrap.dart';
import 'core/map/mapkit_lifecycle_host.dart';
import 'core/push/firebase_push_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseIfConfigured();
  await MapKitBootstrap.initIfConfigured();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    const ProviderScope(
      child: MapKitLifecycleHost(
        child: WalkTalkApp(),
      ),
    ),
  );
}
