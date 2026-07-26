import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:norivo/features/destination_search/destination_search_screen.dart';

void main() {
  testWidgets('renders DestinationSearchScreen with recent searches and chips',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DestinationSearchScreen(),
      ),
    );

    expect(find.text('Choose Destination'), findsOneWidget);
    expect(find.text('Recent Searches'), findsOneWidget);
    expect(find.text('Butterworth Railway Station'), findsOneWidget);
    expect(find.text('KL Sentral'), findsOneWidget);
    expect(find.text('Popular Destinations'), findsOneWidget);
  });
}
