import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walk_talk/app/walk_talk_app.dart';
import 'package:walk_talk/core/map/mapkit_lifecycle_host.dart';

void main() {
  testWidgets('Walk&Talk title is shown', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MapKitLifecycleHost(
          child: WalkTalkApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Сочи 🌴'), findsOneWidget);
    expect(find.text('Драконы и огни'), findsOneWidget);
  });
}
