import 'package:flutter_test/flutter_test.dart';
import 'package:norivo/core/services/alarm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlarmService tests', () {
    test('startAlarm sets isPlaying to true and stopAlarm resets it to false', () async {
      final alarmService = AlarmService();
      expect(alarmService.isPlaying, isFalse);

      await alarmService.startAlarm();
      expect(alarmService.isPlaying, isTrue);

      await alarmService.stopAlarm();
      expect(alarmService.isPlaying, isFalse);
    });
  });
}
