import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norivo/core/models/destination_place.dart';
import 'package:norivo/core/router/app_router.dart';
import 'package:norivo/core/services/alarm_service.dart';
import 'package:norivo/core/services/journey_history_service.dart';
import 'package:norivo/core/services/journey_service.dart';
import 'package:norivo/features/active_journey/active_journey_screen.dart';
import 'package:norivo/features/alarm_ringing/alarm_ringing_screen.dart';
import 'package:norivo/features/history/cancelled_journey_summary_screen.dart';
import 'package:norivo/features/history/journey_summary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAlarmService implements AlarmService {
  @override
  bool get isPlaying => false;

  @override
  Future<void> startAlarm({bool? isVibrationEnabled}) async {}

  @override
  Future<void> stopAlarm() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3 Journey Summary Flow Tests', () {
    testWidgets(
      'Completed journey from AlarmRingingScreen saves record and automatically navigates to JourneySummaryScreen via pushReplacement',
      (tester) async {
        final mockAlarm = MockAlarmService();
        final journeyService = JourneyService(alarmService: mockAlarm);
        JourneyService.instance = journeyService;

        const place = DestinationPlace(
          name: 'Penang Sentral',
          address: 'Butterworth',
          latitude: 5.3992,
          longitude: 100.3638,
        );

        await journeyService.startJourney(destinationPlace: place);

        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const AlarmRingingScreen(destinationPlace: place),
          ),
        );
        await tester.pump();

        expect(find.text('You have arrived'), findsOneWidget);
        expect(find.text('Stop Alarm'), findsOneWidget);

        // Tap Stop Alarm
        await tester.tap(find.text('Stop Alarm'));
        await tester.idle();
        await tester.pump();

        // Verify history service received completed record
        final records = await JourneyHistoryService.instance.getHistoryRecords();
        expect(records.length, 1);
        expect(records.first.destinationName, 'Penang Sentral');
        expect(records.first.status, 'Completed');

        // Verify automatic navigation to JourneySummaryScreen
        expect(find.byType(JourneySummaryScreen), findsOneWidget);
        expect(find.byType(AlarmRingingScreen), findsNothing);
      },
    );

    testWidgets(
      'Cancelled journey from ActiveJourneyScreen saves record and automatically navigates to CancelledJourneySummaryScreen via pushReplacement',
      (tester) async {
        final mockAlarm = MockAlarmService();
        final journeyService = JourneyService(alarmService: mockAlarm);
        JourneyService.instance = journeyService;

        const place = DestinationPlace(
          name: 'Mid Valley Megamall',
          address: 'Kuala Lumpur',
          latitude: 3.1177,
          longitude: 101.6774,
        );

        await journeyService.startJourney(destinationPlace: place);

        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const ActiveJourneyScreen(destinationPlace: place),
          ),
        );
        await tester.pump();

        expect(find.text('End Journey'), findsOneWidget);

        // Tap End Journey
        await tester.tap(find.text('End Journey'));
        await tester.idle();
        await tester.pump();

        // Verify history service received cancelled record
        final records = await JourneyHistoryService.instance.getHistoryRecords();
        expect(records.length, 1);
        expect(records.first.destinationName, 'Mid Valley Megamall');
        expect(records.first.status, 'Cancelled');

        // Verify automatic navigation to CancelledJourneySummaryScreen
        expect(find.byType(CancelledJourneySummaryScreen), findsOneWidget);
        expect(find.byType(ActiveJourneyScreen), findsNothing);
      },
    );

    testWidgets(
      'Duplicate callback protection: rapid taps on End Journey triggers navigation and saving only once',
      (tester) async {
        final mockAlarm = MockAlarmService();
        final journeyService = JourneyService(alarmService: mockAlarm);
        JourneyService.instance = journeyService;

        const place = DestinationPlace(
          name: 'KLCC Twin Towers',
          address: 'Kuala Lumpur',
          latitude: 3.1579,
          longitude: 101.7116,
        );

        await journeyService.startJourney(destinationPlace: place);

        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const ActiveJourneyScreen(destinationPlace: place),
          ),
        );
        await tester.pump();

        // Tap End Journey multiple times rapidly
        await tester.tap(find.text('End Journey'));
        await tester.tap(find.text('End Journey'));
        await tester.tap(find.text('End Journey'));
        await tester.idle();
        await tester.pump();

        final records = await JourneyHistoryService.instance.getHistoryRecords();
        expect(records.length, 1);
        expect(find.byType(CancelledJourneySummaryScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Back-navigation behavior: popping summary screen returns to initial route, not ActiveJourneyScreen',
      (tester) async {
        final mockAlarm = MockAlarmService();
        final journeyService = JourneyService(alarmService: mockAlarm);
        JourneyService.instance = journeyService;

        const place = DestinationPlace(
          name: 'Ipoh Railway Station',
          address: 'Ipoh',
          latitude: 4.5975,
          longitude: 101.0731,
        );

        await journeyService.startJourney(destinationPlace: place);

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRouter.home,
            onGenerateRoute: AppRouter.onGenerateRoute,
            routes: {
              AppRouter.home: (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ActiveJourneyScreen(
                              destinationPlace: place,
                            ),
                          ),
                        );
                      },
                      child: const Text('Start Active Journey Screen'),
                    ),
                  ),
            },
          ),
        );
        await tester.pump();

        // Navigate to ActiveJourneyScreen
        await tester.tap(find.text('Start Active Journey Screen'));
        await tester.idle();
        await tester.pump();
        expect(find.byType(ActiveJourneyScreen), findsOneWidget);

        // Tap End Journey to replace ActiveJourneyScreen with CancelledSummaryScreen
        await tester.tap(find.text('End Journey'));
        await tester.idle();
        await tester.pump();

        expect(find.byType(CancelledJourneySummaryScreen), findsOneWidget);
        expect(find.byType(ActiveJourneyScreen), findsNothing);

        // Pop summary screen (Simulate back button on summary screen)
        final dynamic state = tester.state(find.byType(CancelledJourneySummaryScreen));
        Navigator.of(state.context).pop();
        await tester.idle();
        await tester.pump();

        // Should return to Home screen, NOT ActiveJourneyScreen!
        expect(find.text('Start Active Journey Screen'), findsOneWidget);
        expect(find.byType(ActiveJourneyScreen), findsNothing);
      },
    );
  });
}
