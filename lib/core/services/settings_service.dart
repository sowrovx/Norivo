import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService({SharedPreferences? preferences}) {
    _preferences = preferences;
  }

  static final SettingsService instance = SettingsService();

  SharedPreferences? _preferences;

  /// ValueNotifier for app-wide theme mode (ThemeMode.light or ThemeMode.dark).
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static const String keyDefaultRadius = 'default_arrival_radius';
  static const String keyAlarmVolume = 'alarm_volume';
  static const String keySelectedSound = 'selected_sound';
  static const String keyVibration = 'is_vibration_enabled';
  static const String keyVoice = 'is_voice_enabled';
  static const String keyHighAccuracyGps = 'is_high_accuracy_gps';
  static const String keyBackgroundTracking = 'is_background_tracking';
  static const String keyTravelMode = 'selected_travel_mode';
  static const String keyDarkMode = 'is_dark_mode';

  Future<SharedPreferences> _getPrefs() async {
    if (_preferences != null) return _preferences!;
    _preferences = await SharedPreferences.getInstance();
    return _preferences!;
  }

  /// Gets whether dark mode is enabled. Defaults to false.
  Future<bool> isDarkMode() async {
    try {
      final prefs = await _getPrefs();
      final isDark = prefs.getBool(keyDarkMode) ?? false;
      themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
      return isDark;
    } catch (e) {
      debugPrint('Error reading dark mode setting: $e');
      return false;
    }
  }

  /// Saves whether dark mode is enabled and updates themeModeNotifier.
  Future<bool> setDarkMode(bool isDark) async {
    try {
      themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
      final prefs = await _getPrefs();
      return await prefs.setBool(keyDarkMode, isDark);
    } catch (e) {
      debugPrint('Error saving dark mode setting: $e');
      return false;
    }
  }

  /// Gets the default arrival radius string (e.g. '1 km'). Defaults to '1 km'.
  Future<String> getDefaultRadius() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(keyDefaultRadius) ?? '1 km';
    } catch (e) {
      debugPrint('Error reading default radius: $e');
      return '1 km';
    }
  }

  /// Gets the saved alarm volume (0.0 to 1.0). Defaults to 0.8.
  Future<double> getAlarmVolume() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getDouble(keyAlarmVolume) ?? 0.8;
    } catch (e) {
      debugPrint('Error reading alarm volume: $e');
      return 0.8;
    }
  }

  /// Saves the alarm volume (0.0 to 1.0).
  Future<bool> setAlarmVolume(double volume) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setDouble(keyAlarmVolume, volume);
    } catch (e) {
      debugPrint('Error saving alarm volume: $e');
      return false;
    }
  }

  /// Gets whether vibration is enabled. Defaults to true.
  Future<bool> isVibrationEnabled() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(keyVibration) ?? true;
    } catch (e) {
      debugPrint('Error reading vibration setting: $e');
      return true;
    }
  }

  /// Saves whether vibration is enabled.
  Future<bool> setVibrationEnabled(bool enabled) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setBool(keyVibration, enabled);
    } catch (e) {
      debugPrint('Error saving vibration setting: $e');
      return false;
    }
  }

  /// Saves the default arrival radius string (e.g. '250 m', '500 m', '1 km', '2 km', '5 km').
  Future<bool> setDefaultRadius(String radius) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setString(keyDefaultRadius, radius);
    } catch (e) {
      debugPrint('Error saving default radius: $e');
      return false;
    }
  }

  /// Converts radius string ('250 m', '500 m', '1 km', '2 km', '5 km') to index (0..4).
  static int radiusToIndex(String radius) {
    switch (radius) {
      case '250 m':
        return 0;
      case '500 m':
        return 1;
      case '1 km':
        return 2;
      case '2 km':
        return 3;
      case '5 km':
        return 4;
      default:
        return 2;
    }
  }

  /// Converts index (0..4) to radius string.
  static String indexToRadius(int index) {
    switch (index) {
      case 0:
        return '250 m';
      case 1:
        return '500 m';
      case 2:
        return '1 km';
      case 3:
        return '2 km';
      case 4:
        return '5 km';
      default:
        return '1 km';
    }
  }
}
