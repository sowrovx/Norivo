import 'package:flutter_test/flutter_test.dart';
import 'package:norivo/core/models/journey_history_record.dart';
import 'package:norivo/core/services/journey_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('JourneyHistoryService tests', () {
    test('addRecord saves record persistently and returns in reverse chronological order', () async {
      final service = JourneyHistoryService();

      final record1 = JourneyHistoryRecord(
        id: '1',
        destinationName: 'KL Sentral',
        destinationAddress: 'Kuala Lumpur',
        destinationLatitude: 3.1342,
        destinationLongitude: 101.6861,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
        totalDurationSeconds: 3600,
        totalDistanceMeters: 12000.0,
        alarmThresholdMeters: 1000.0,
        travelMode: 'Drive',
        status: 'Completed',
      );

      final record2 = JourneyHistoryRecord(
        id: '2',
        destinationName: 'Mid Valley',
        destinationAddress: 'Kuala Lumpur',
        destinationLatitude: 3.1177,
        destinationLongitude: 101.6774,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 30)),
        totalDurationSeconds: 1800,
        totalDistanceMeters: 5000.0,
        alarmThresholdMeters: 500.0,
        travelMode: 'Transit',
        status: 'Cancelled',
      );

      await service.addRecord(record1);
      await service.addRecord(record2);

      final records = await service.getHistoryRecords();
      expect(records.length, 2);
      expect(records.first.destinationName, 'Mid Valley');
      expect(records.last.destinationName, 'KL Sentral');
      expect(records.first.status, 'Cancelled');
      expect(records.last.status, 'Completed');
    });

    test('clearHistory removes all records', () async {
      final service = JourneyHistoryService();

      final record = JourneyHistoryRecord(
        id: '1',
        destinationName: 'KL Sentral',
        destinationLatitude: 3.1342,
        destinationLongitude: 101.6861,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        totalDurationSeconds: 300,
        totalDistanceMeters: 2000.0,
        alarmThresholdMeters: 1000.0,
        travelMode: 'Drive',
        status: 'Completed',
      );

      await service.addRecord(record);
      var records = await service.getHistoryRecords();
      expect(records.length, 1);

      await service.clearHistory();
      records = await service.getHistoryRecords();
      expect(records.isEmpty, true);
    });
  });
}
