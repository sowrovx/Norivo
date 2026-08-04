import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'settings_service.dart';

enum LocationPermissionState { unknown, granted, denied, permanentlyDenied }

class LocationService {
  const LocationService._();

  static Future<LocationPermissionState> checkAndRequestPermission({
    bool isBackground = false,
  }) async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      if (isBackground &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        final alwaysStatus = await Permission.locationAlways.status;
        if (!alwaysStatus.isGranted) {
          await Permission.locationAlways.request();
        }
      }
      return LocationPermissionState.granted;
    }

    if (status.isPermanentlyDenied) {
      return LocationPermissionState.permanentlyDenied;
    }

    final requested = await Permission.location.request();
    if (requested.isGranted) {
      if (isBackground &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        final alwaysStatus = await Permission.locationAlways.status;
        if (!alwaysStatus.isGranted) {
          await Permission.locationAlways.request();
        }
      }
      return LocationPermissionState.granted;
    }

    if (requested.isPermanentlyDenied) {
      return LocationPermissionState.permanentlyDenied;
    }

    return LocationPermissionState.denied;
  }

  static Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    final permissionState = await checkAndRequestPermission();
    if (permissionState != LocationPermissionState.granted) {
      return null;
    }

    final isHighAccuracy = await SettingsService.instance.isHighAccuracyGps();
    final accuracy = isHighAccuracy ? LocationAccuracy.high : LocationAccuracy.medium;

    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: accuracy),
    );
  }

  static Future<void> requestNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  static Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    bool isBackgroundTracking = true,
  }) {
    late final LocationSettings locationSettings;

    if (isBackgroundTracking && defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Norivo Journey Active',
          notificationText: 'Tracking location in background to wake you up before arrival.',
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
          enableWakeLock: true,
        ),
      );
    } else if (isBackgroundTracking &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      locationSettings = AppleSettings(
        accuracy: accuracy,
        activityType: ActivityType.fitness,
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  static LocationPermissionState mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted) {
      return LocationPermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return LocationPermissionState.permanentlyDenied;
    }
    return LocationPermissionState.denied;
  }
}
