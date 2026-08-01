import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:norivo/features/settings/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('renders SettingsScreen with all preference sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    expect(find.text('Settings'), findsNWidgets(2));
    expect(find.text('Alarm & Sound'), findsOneWidget);
    expect(find.text('Alarm Volume'), findsOneWidget);
    expect(find.text('Wake-up Sound'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);

    final appPreferencesFinder = find.text('App Preferences');
    await tester.scrollUntilVisible(appPreferencesFinder, 200.0);

    expect(find.text('Location & Tracking'), findsOneWidget);
    expect(find.text('Default Wake-up Distance'), findsOneWidget);
    expect(find.text('App Preferences'), findsOneWidget);
    expect(find.text('Default Travel Mode'), findsOneWidget);
  });

  testWidgets('allows selecting default wake-up radius choice chips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    final chipFinder = find.text('500 m');
    await tester.scrollUntilVisible(chipFinder, 200.0);
    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    expect(find.text('500 m'), findsNWidgets(2));
  });
}
