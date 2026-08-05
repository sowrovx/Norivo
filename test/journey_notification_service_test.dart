import 'package:flutter_test/flutter_test.dart';
import 'package:norivo/core/models/destination_place.dart';
import 'package:norivo/core/services/journey_notification_service.dart';

void main() {
  group('JourneyNotificationService tests', () {
    test('buildTitle returns formatted destination title', () {
      const place = DestinationPlace(
        name: 'KL Sentral',
        address: 'Kuala Lumpur',
        latitude: 3.1342,
        longitude: 101.6861,
      );

      final title = JourneyNotificationService.buildTitle(place);
      expect(title, 'Heading to KL Sentral');
    });

    test('buildContent formats distance, ETA, and status correctly', () {
      final content = JourneyNotificationService.buildContent(
        distanceMeters: 2500.0,
        durationSeconds: 600.0,
        isNearDestination: false,
      );

      expect(content.contains('2.5 km'), true);
      expect(content.contains('ETA: 10 mins'), true);
      expect(content.contains('In Progress'), true);
    });

    test('buildContent displays Arriving Soon when near destination', () {
      final content = JourneyNotificationService.buildContent(
        distanceMeters: 400.0,
        durationSeconds: 120.0,
        isNearDestination: true,
      );

      expect(content.contains('400 m'), true);
      expect(content.contains('Arriving Soon'), true);
    });
  });
}
