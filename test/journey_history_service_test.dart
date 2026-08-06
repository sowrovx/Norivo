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

    test('deleteRecord removes a specific record by id', () async {
      final service = JourneyHistoryService();

      final record1 = JourneyHistoryRecord(
        id: 'rec_100',
        destinationName: 'Penang Hill',
        destinationLatitude: 5.4084,
        destinationLongitude: 100.2772,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        totalDurationSeconds: 600,
        totalDistanceMeters: 3000.0,
        alarmThresholdMeters: 500.0,
        travelMode: 'Drive',
        status: 'Completed',
      );

      final record2 = JourneyHistoryRecord(
        id: 'rec_200',
        destinationName: 'Batu Caves',
        destinationLatitude: 3.2379,
        destinationLongitude: 101.6840,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        totalDurationSeconds: 1200,
        totalDistanceMeters: 8000.0,
        alarmThresholdMeters: 1000.0,
        travelMode: 'Drive',
        status: 'Completed',
      );

      await service.addRecord(record1);
      await service.addRecord(record2);

      var records = await service.getHistoryRecords();
      expect(records.length, 2);

      await service.deleteRecord('rec_100');
      records = await service.getHistoryRecords();
      expect(records.length, 1);
      expect(records.first.id, 'rec_200');
    });

    test('regression test: two completed journeys remain Completed after storage reload', () async {
      final service = JourneyHistoryService();

      final id1 = JourneyHistoryRecord.generateUniqueId();
      final record1 = JourneyHistoryRecord(
        id: id1,
        destinationName: 'Station Alpha',
        destinationAddress: 'Alpha Address',
        destinationLatitude: 3.1000,
        destinationLongitude: 101.6000,
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
        totalDurationSeconds: 3600,
        totalDistanceMeters: 15000.0,
        alarmThresholdMeters: 1000.0,
        travelMode: 'Train',
        status: 'Completed',
      );

      final id2 = JourneyHistoryRecord.generateUniqueId();
      final record2 = JourneyHistoryRecord(
        id: id2,
        destinationName: 'Station Beta',
        destinationAddress: 'Beta Address',
        destinationLatitude: 3.2000,
        destinationLongitude: 101.7000,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        totalDurationSeconds: 3600,
        totalDistanceMeters: 18000.0,
        alarmThresholdMeters: 1000.0,
        travelMode: 'Train',
        status: 'Completed',
      );

      await service.addRecord(record1);
      await service.addRecord(record2);

      // Reload storage
      final newServiceInstance = JourneyHistoryService();
      final reloadedRecords = await newServiceInstance.getHistoryRecords();

      expect(reloadedRecords.length, 2);
      final rec2 = reloadedRecords.firstWhere((r) => r.id == id2);
      final rec1 = reloadedRecords.firstWhere((r) => r.id == id1);

      expect(rec1.status, 'Completed');
      expect(rec2.status, 'Completed');
      expect(rec1.destinationName, 'Station Alpha');
      expect(rec2.destinationName, 'Station Beta');
      expect(rec1.id, id1);
      expect(rec2.id, id2);
    });

    test('regression test: completed journey followed by cancelled journey keeps distinct statuses', () async {
      final service = JourneyHistoryService();

      final id1 = JourneyHistoryRecord.generateUniqueId();
      final recordCompleted = JourneyHistoryRecord(
        id: id1,
        destinationName: 'Completed Station',
        destinationLatitude: 3.3000,
        destinationLongitude: 101.8000,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().subtract(const Duration(hours: 3)),
        totalDurationSeconds: 3600,
        totalDistanceMeters: 20000.0,
        alarmThresholdMeters: 1000.0,
        travelMode: 'Drive',
        status: 'Completed',
      );

      final id2 = JourneyHistoryRecord.generateUniqueId();
      final recordCancelled = JourneyHistoryRecord(
        id: id2,
        destinationName: 'Cancelled Station',
        destinationLatitude: 3.4000,
        destinationLongitude: 101.9000,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
        totalDurationSeconds: 1200,
        totalDistanceMeters: 5000.0,
        alarmThresholdMeters: 500.0,
        travelMode: 'Drive',
        status: 'Cancelled',
      );

      await service.addRecord(recordCompleted);
      await service.addRecord(recordCancelled);

      // Reload storage
      final freshService = JourneyHistoryService();
      final reloadedRecords = await freshService.getHistoryRecords();

      expect(reloadedRecords.length, 2);
      final completedRec = reloadedRecords.firstWhere((r) => r.id == id1);
      final cancelledRec = reloadedRecords.firstWhere((r) => r.id == id2);

      expect(completedRec.status, 'Completed');
      expect(cancelledRec.status, 'Cancelled');
      expect(completedRec.id, id1);
      expect(cancelledRec.id, id2);
    });
  });
}
