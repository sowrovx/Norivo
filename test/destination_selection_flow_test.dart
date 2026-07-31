import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norivo/core/models/destination_place.dart';
import 'package:norivo/core/services/destination_search_service.dart';
import 'package:norivo/features/destination_search/destination_search_screen.dart';
import 'package:norivo/shared/widgets/primary_button.dart';

void main() {
  testWidgets('Top app bar does not contain the extra top-right icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DestinationSearchScreen()),
    );

    expect(find.text('Choose Destination'), findsOneWidget);
    // Header should only contain back button and title, no top-right mic/menu icon container in row
    final headerRow = find.ancestor(
      of: find.text('Choose Destination'),
      matching: find.byType(Row),
    );
    expect(headerRow, findsOneWidget);
    expect(
      find.descendant(of: headerRow, matching: find.byType(IconButton)),
      findsOneWidget, // Only the back button
    );
  });

  testWidgets('Continue remains disabled until a real destination is selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DestinationSearchScreen()),
    );

    // Initial state: Continue should be disabled
    final buttonBefore = tester.widget<PrimaryButton>(
      find.byType(PrimaryButton),
    );
    expect(buttonBefore.onPressed, isNull);

    // Enter query text without tapping a search result: Continue should remain disabled
    await tester.enterText(find.byType(TextField), 'kuala lumpur');
    await tester.pump();

    final buttonAfterTyping = tester.widget<PrimaryButton>(
      find.byType(PrimaryButton),
    );
    expect(buttonAfterTyping.onPressed, isNull);
  });

  test('DestinationPlace stores coordinates correctly', () {
    const place = DestinationPlace(
      name: 'Home',
      address: 'Home address',
      latitude: 3.14,
      longitude: 101.68,
    );

    expect(place.latitude, 3.14);
    expect(place.longitude, 101.68);
  });

  test('DestinationSearchService surfaces a clear error for failed requests', () async {
    final client = MockClient(
      (request) async => http.Response('server error', 503),
    );
    final service = DestinationSearchService(client: client);

    await expectLater(
      service.search('London'),
      throwsA(isA<DestinationSearchException>()),
    );
  });

  test('DestinationSearchService formats distance values correctly', () {
    expect(DestinationSearchService.formatDistance(650), '650 m');
    expect(DestinationSearchService.formatDistance(1500), '1.5 km');
  });
}
