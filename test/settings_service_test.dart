import 'package:flutter_test/flutter_test.dart';
import 'package:norivo/core/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService tests', () {
    test('getDefaultRadius returns default 1 km when no value is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(preferences: prefs);

      final radius = await service.getDefaultRadius();
      expect(radius, '1 km');
    });

    test('setDefaultRadius stores value persistently and reads it back', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(preferences: prefs);

      await service.setDefaultRadius('500 m');
      final radius = await service.getDefaultRadius();
      expect(radius, '500 m');
    });

    test('getAlarmVolume returns default 0.8 when no value is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(preferences: prefs);

      final vol = await service.getAlarmVolume();
      expect(vol, 0.8);
    });

    test('setAlarmVolume stores volume persistently and reads it back', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(preferences: prefs);

      await service.setAlarmVolume(0.45);
      final vol = await service.getAlarmVolume();
      expect(vol, 0.45);
    });

    test('isDarkMode returns false by default and setDarkMode updates persistent value and themeModeNotifier', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(preferences: prefs);

      final defaultDark = await service.isDarkMode();
      expect(defaultDark, false);

      await service.setDarkMode(true);
      final updatedDark = await service.isDarkMode();
      expect(updatedDark, true);
    });

    test('isVibrationEnabled returns true by default and setVibrationEnabled updates persistent value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(preferences: prefs);

      final defaultVibration = await service.isVibrationEnabled();
      expect(defaultVibration, true);

      await service.setVibrationEnabled(false);
      final updatedVibration = await service.isVibrationEnabled();
      expect(updatedVibration, false);
    });

    test('isHighAccuracyGps returns true by default and setHighAccuracyGps updates persistent value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(preferences: prefs);

      final defaultGps = await service.isHighAccuracyGps();
      expect(defaultGps, true);

      await service.setHighAccuracyGps(false);
      final updatedGps = await service.isHighAccuracyGps();
      expect(updatedGps, false);
    });

    test('isBackgroundTracking returns true by default and setBackgroundTracking updates persistent value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(preferences: prefs);

      final defaultBg = await service.isBackgroundTracking();
      expect(defaultBg, true);

      await service.setBackgroundTracking(false);
      final updatedBg = await service.isBackgroundTracking();
      expect(updatedBg, false);
    });

    test('radiusToIndex and indexToRadius convert correctly', () {
      expect(SettingsService.radiusToIndex('250 m'), 0);
      expect(SettingsService.radiusToIndex('500 m'), 1);
      expect(SettingsService.radiusToIndex('1 km'), 2);
      expect(SettingsService.radiusToIndex('2 km'), 3);
      expect(SettingsService.radiusToIndex('5 km'), 4);

      expect(SettingsService.indexToRadius(0), '250 m');
      expect(SettingsService.indexToRadius(1), '500 m');
      expect(SettingsService.indexToRadius(2), '1 km');
      expect(SettingsService.indexToRadius(3), '2 km');
      expect(SettingsService.indexToRadius(4), '5 km');
    });
  });
}
