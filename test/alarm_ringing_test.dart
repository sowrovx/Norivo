import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:norivo/features/alarm_ringing/alarm_ringing_screen.dart';

void main() {
  testWidgets('shows arrival and alarm actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlarmRingingScreen()));
    await tester.pump();

    expect(find.text('You have arrived'), findsOneWidget);
    expect(find.text('Stop Alarm'), findsOneWidget);
    expect(find.text('Snooze'), findsOneWidget);
  });
}
