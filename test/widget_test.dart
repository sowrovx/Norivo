import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:norivo/app/app.dart';

void main() {
  testWidgets('shows the Norivo splash screen and navigates to HomeScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NorivoApp());

    expect(find.text('Norivo'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Good Morning 👋'), findsOneWidget);
    expect(find.text("Today's Journey"), findsOneWidget);
  });
}
