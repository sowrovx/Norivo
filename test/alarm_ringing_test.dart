import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:norivo/core/models/destination_place.dart';
import 'package:norivo/features/alarm_ringing/alarm_ringing_screen.dart';

void main() {
  testWidgets('shows arrival and alarm actions with fallback destination', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlarmRingingScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('You have arrived'), findsOneWidget);
    expect(find.text('Selected Destination'), findsOneWidget);
    expect(find.text('Stop Alarm'), findsOneWidget);
    expect(find.text('Snooze'), findsOneWidget);
  });

  testWidgets('shows arrival with passed DestinationPlace', (tester) async {
    const place = DestinationPlace(
      name: 'Central Station',
      address: 'Kuala Lumpur',
      latitude: 3.1342,
      longitude: 101.6861,
    );

    await tester.pumpWidget(
      const MaterialApp(home: AlarmRingingScreen(destinationPlace: place)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('You have arrived'), findsOneWidget);
    expect(find.text('Central Station'), findsOneWidget);
    expect(find.textContaining('Current time:'), findsOneWidget);
  });
}
