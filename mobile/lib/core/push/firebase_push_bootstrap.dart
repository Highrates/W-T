import 'package:firebase_core/firebase_core.dart';

import '../config/firebase_config.dart';

/// Initializes Firebase when dart-defines are provided.
Future<void> initFirebaseIfConfigured() async {
  if (!FirebaseConfig.isConfigured) return;
  if (Firebase.apps.isNotEmpty) return;

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: FirebaseConfig.apiKey,
      appId: FirebaseConfig.appId,
      messagingSenderId: FirebaseConfig.messagingSenderId,
      projectId: FirebaseConfig.projectId,
      iosBundleId: FirebaseConfig.iosBundleId,
    ),
  );
}
