import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:norivo/core/models/journey_history_record.dart';
import 'package:norivo/features/history/cancelled_journey_summary_screen.dart';
import 'package:norivo/features/history/journey_summary_screen.dart';

void main() {
  testWidgets('renders JourneySummaryScreen with real journey metrics', (
    WidgetTester tester,
  ) async {
    final record = JourneyHistoryRecord(
      id: 'test_record_123',
      destinationName: 'KLCC Station',
      destinationAddress: 'Kuala Lumpur, Malaysia',
      destinationLatitude: 3.1579,
      destinationLongitude: 101.7116,
      startTime: DateTime(2026, 8, 6, 14, 0),
      endTime: DateTime(2026, 8, 6, 14, 30),
      totalDurationSeconds: 1800, // 30 mins
      totalDistanceMeters: 12000.0, // 12 km
      alarmThresholdMeters: 1000.0,
      travelMode: 'Train',
      status: 'Completed',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: JourneySummaryScreen(record: record),
      ),
    );

    // Verify title and destination header
    expect(find.text('Journey Summary'), findsOneWidget);
    expect(find.text('KLCC Station'), findsNWidgets(2));
    expect(find.text('Kuala Lumpur, Malaysia'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    // Verify hero illustration
    expect(find.text('Journey Completed Safely'), findsOneWidget);

    // Verify Journey Information card values
    expect(find.text('30 mins'), findsNWidgets(2)); // Total Travel Time + Duration Insight
    expect(find.text('12.0 km'), findsNWidgets(2)); // Total Distance + Distance Insight
    expect(find.text('1 km'), findsOneWidget); // Alarm Threshold
    expect(find.text('Train'), findsOneWidget);

    // Verify real Journey Insights metrics (Distance, Duration, Average Speed)
    expect(find.text('Travel Distance'), findsOneWidget);
    expect(find.text('Travel Duration'), findsOneWidget);
    expect(find.text('Average Speed'), findsOneWidget);
    expect(find.text('24.0 km/h'), findsOneWidget); // 12km / 0.5h = 24.0 km/h

    // Verify buttons
    expect(find.text('Return Home'), findsOneWidget);
    expect(find.text('View Journey History'), findsOneWidget);
  });

  testWidgets('renders CancelledJourneySummaryScreen with cancelled journey metrics', (
    WidgetTester tester,
  ) async {
    final record = JourneyHistoryRecord(
      id: 'test_cancelled_456',
      destinationName: 'Penang Station',
      destinationAddress: 'Penang, Malaysia',
      destinationLatitude: 5.4164,
      destinationLongitude: 100.3327,
      startTime: DateTime(2026, 8, 6, 10, 0),
      endTime: DateTime(2026, 8, 6, 10, 15),
      totalDurationSeconds: 900, // 15 mins
      totalDistanceMeters: 5000.0, // 5 km
      alarmThresholdMeters: 500.0,
      travelMode: 'Drive',
      status: 'Cancelled',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CancelledJourneySummaryScreen(record: record),
      ),
    );

    expect(find.text('Journey Summary'), findsOneWidget);
    expect(find.text('Penang Station'), findsNWidgets(2));
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Journey Cancelled'), findsOneWidget);
    expect(find.text('15 mins'), findsNWidgets(2));
    expect(find.text('5.0 km'), findsNWidgets(2));
    expect(find.text('500 m'), findsOneWidget);
    expect(find.text('20.0 km/h'), findsOneWidget); // 5km / 0.25h = 20.0 km/h
  });

  testWidgets('handles missing fields gracefully with Not available text', (
    WidgetTester tester,
  ) async {
    final emptyRecord = JourneyHistoryRecord(
      id: 'empty_789',
      destinationName: '',
      destinationAddress: null,
      destinationLatitude: 0.0,
      destinationLongitude: 0.0,
      startTime: DateTime(2026, 8, 6, 12, 0),
      endTime: DateTime(2026, 8, 6, 12, 0),
      totalDurationSeconds: 0,
      totalDistanceMeters: 0.0,
      alarmThresholdMeters: 0.0,
      travelMode: '',
      status: 'Completed',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: JourneySummaryScreen(record: emptyRecord),
      ),
    );

    expect(find.text('Not available'), findsWidgets);
  });
}
