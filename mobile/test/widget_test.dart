import 'package:flutter_test/flutter_test.dart';

import 'package:walk_talk/app/walk_talk_app.dart';

void main() {
  testWidgets('Walk&Talk title is shown', (WidgetTester tester) async {
    await tester.pumpWidget(const WalkTalkApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Сочи 🌴'), findsOneWidget);
    expect(find.text('Драконы и огни'), findsOneWidget);
  });
}
