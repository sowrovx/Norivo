import 'package:flutter_test/flutter_test.dart';
import 'package:norivo/core/models/destination_place.dart';
import 'package:norivo/core/services/alarm_service.dart';
import 'package:norivo/core/services/journey_service.dart';
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

  group('JourneyService tests', () {
    test('startJourney initializes active journey state and stopJourney clears it', () async {
      final service = JourneyService(alarmService: MockAlarmService());
      expect(service.hasActiveJourney, false);
      expect(service.currentJourney, null);

      const place = DestinationPlace(
        name: 'KL Sentral',
        address: 'Kuala Lumpur',
        latitude: 3.1342,
        longitude: 101.6861,
      );

      await service.startJourney(
        destinationPlace: place,
        alarmThresholdMeters: 1000.0,
        isVibrationEnabled: true,
      );

      expect(service.hasActiveJourney, true);
      expect(service.currentJourney?.destinationPlace.name, 'KL Sentral');
      expect(service.currentJourney?.alarmThresholdMeters, 1000.0);

      await service.stopJourney();
      expect(service.hasActiveJourney, false);
      expect(service.currentJourney, null);
    });

    test('startJourney does not duplicate tracking for same destination', () async {
      final service = JourneyService(alarmService: MockAlarmService());

      const place = DestinationPlace(
        name: 'KL Sentral',
        address: 'Kuala Lumpur',
        latitude: 3.1342,
        longitude: 101.6861,
      );

      await service.startJourney(destinationPlace: place);
      final firstStartTime = service.currentJourney?.startTime;

      await service.startJourney(destinationPlace: place);
      final secondStartTime = service.currentJourney?.startTime;

      expect(firstStartTime, secondStartTime);

      await service.stopJourney();
    });

    test('startJourney with new destination clears old state and starts fresh session', () async {
      final service = JourneyService(alarmService: MockAlarmService());

      const place1 = DestinationPlace(
        name: 'KL Sentral',
        address: 'Kuala Lumpur',
        latitude: 3.1342,
        longitude: 101.6861,
      );

      const place2 = DestinationPlace(
        name: 'Mid Valley',
        address: 'Kuala Lumpur',
        latitude: 3.1177,
        longitude: 101.6774,
      );

      await service.startJourney(destinationPlace: place1);
      expect(service.currentJourney?.destinationPlace.name, 'KL Sentral');

      await service.startJourney(destinationPlace: place2);
      expect(service.currentJourney?.destinationPlace.name, 'Mid Valley');
      expect(service.routeResultNotifier.value, null);

      await service.stopJourney();
      expect(service.hasActiveJourney, false);
      expect(service.activeJourneyNotifier.value, null);
      expect(service.currentPositionNotifier.value, null);
      expect(service.routeResultNotifier.value, null);
    });

    test('restoreActiveJourney restores persisted journey after app reopening', () async {
      final service1 = JourneyService(alarmService: MockAlarmService());

      const place = DestinationPlace(
        name: 'Penang International Airport',
        address: 'Bayan Lepas, Penang',
        latitude: 5.2971,
        longitude: 100.2769,
      );

      await service1.startJourney(
        destinationPlace: place,
        alarmThresholdMeters: 2000.0,
        isVibrationEnabled: false,
      );

      final service2 = JourneyService(alarmService: MockAlarmService());
      expect(service2.hasActiveJourney, false);

      final restored = await service2.restoreActiveJourney();
      expect(restored, isNotNull);
      expect(restored?.destinationPlace.name, 'Penang International Airport');
      expect(restored?.alarmThresholdMeters, 2000.0);
      expect(restored?.isVibrationEnabled, false);
      expect(service2.hasActiveJourney, true);

      await service2.stopJourney();
      expect(service2.hasActiveJourney, false);
    });

    test('stopJourney with explicitStatus Completed and Cancelled saves correct status', () async {
      final service = JourneyService(alarmService: MockAlarmService());

      const place = DestinationPlace(
        name: 'Butterworth Station',
        address: 'Penang',
        latitude: 5.3992,
        longitude: 100.3638,
      );

      await service.startJourney(destinationPlace: place);
      await service.stopJourney(explicitStatus: 'Completed');
      expect(service.hasActiveJourney, false);

      await service.startJourney(destinationPlace: place);
      await service.stopJourney(explicitStatus: 'Cancelled');
      expect(service.hasActiveJourney, false);
    });
  });
}
