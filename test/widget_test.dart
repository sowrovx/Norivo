import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:norivo/main.dart';

void main() {
  testWidgets('shows the Norivo splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Norivo'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
