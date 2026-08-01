import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:norivo/core/models/destination_place.dart';
import 'package:norivo/features/active_journey/active_journey_screen.dart';
import 'package:norivo/features/alarm_setup/alarm_setup_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('renders error view when no destination is provided to AlarmSetupScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AlarmSetupScreen()),
    );

    expect(find.text('No destination selected'), findsOneWidget);
    expect(find.text('Choose Destination'), findsOneWidget);
  });

  testWidgets('renders AlarmSetupScreen with DestinationPlace', (
    WidgetTester tester,
  ) async {
    const place = DestinationPlace(
      name: 'KL Sentral',
      address: 'Kuala Lumpur',
      latitude: 3.1342,
      longitude: 101.6861,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AlarmSetupScreen(destinationPlace: place),
      ),
    );

    expect(find.text('Set Alarm'), findsOneWidget);
    expect(find.text('KL Sentral'), findsNWidgets(2));
    expect(find.text('Kuala Lumpur'), findsOneWidget);
    expect(find.text('Wake-up Distance'), findsOneWidget);
    expect(find.text('Alarm Settings'), findsOneWidget);
    expect(find.text('Start Journey'), findsOneWidget);
  });

  testWidgets('renders error view when no destination is provided to ActiveJourneyScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ActiveJourneyScreen()),
    );

    expect(find.text('No destination selected'), findsOneWidget);
    expect(find.text('Choose Destination'), findsOneWidget);
  });

  testWidgets('renders ActiveJourneyScreen with DestinationPlace', (
    WidgetTester tester,
  ) async {
    const place = DestinationPlace(
      name: 'KL Sentral',
      address: 'Kuala Lumpur',
      latitude: 3.1342,
      longitude: 101.6861,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ActiveJourneyScreen(destinationPlace: place),
      ),
    );

    expect(find.text('Active Journey'), findsOneWidget);
    expect(find.text('KL Sentral'), findsNWidgets(2));
    expect(find.text('End Journey'), findsOneWidget);
  });
}
