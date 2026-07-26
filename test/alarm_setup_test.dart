import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:norivo/features/alarm_setup/alarm_setup_screen.dart';

void main() {
  testWidgets('renders AlarmSetupScreen with destination and wake-up options',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AlarmSetupScreen(destinationName: 'Butterworth Railway Station'),
      ),
    );

    expect(find.text('Set Alarm'), findsOneWidget);
    expect(find.text('Butterworth Railway Station'), findsNWidgets(2));
    expect(find.text('Wake-up Distance'), findsOneWidget);
    expect(find.text('1 km'), findsOneWidget);
    expect(find.text('Alarm Settings'), findsOneWidget);
    expect(find.text('Start Journey'), findsOneWidget);
    expect(find.text('Preview Alarm'), findsOneWidget);
  });
}
