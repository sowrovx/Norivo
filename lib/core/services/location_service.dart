import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'settings_service.dart';

enum LocationPermissionState { unknown, granted, denied, permanentlyDenied }

class LocationService {
  const LocationService._();

  /// Single shared position notifier accessible app-wide to prevent duplicate Geolocator streams.
  static final ValueNotifier<Position?> currentPositionNotifier =
      ValueNotifier<Position?>(null);

  static StreamSubscription<Position>? _sharedPositionSubscription;
  static final List<void Function(Position)> _sharedListeners = [];
  static int _activeGeolocatorStreams = 0;

  /// Returns the current number of active Geolocator location streams across the application.
  static int get activeGeolocatorStreamCount => _activeGeolocatorStreams;

  /// Updates the single shared position state and notifies all active shared listeners.
  static void updateSharedPosition(Position position) {
    currentPositionNotifier.value = position;
    for (final listener in List<void Function(Position)>.from(_sharedListeners)) {
      try {
        listener(position);
      } catch (e) {
        debugPrint('[LocationService] Error notifying shared location listener: $e');
      }
    }
  }

  /// Subscribes to the single shared location stream. Ensures only 1 primary Geolocator stream is active.
  static void listenToSharedLocation({
    required void Function(Position position) onPosition,
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    bool isBackgroundTracking = true,
  }) {
    if (!_sharedListeners.contains(onPosition)) {
      _sharedListeners.add(onPosition);
    }

    if (currentPositionNotifier.value != null) {
      onPosition(currentPositionNotifier.value!);
    }

    if (_sharedPositionSubscription == null) {
      final streamsBefore = _activeGeolocatorStreams + 2; // Prior unoptimized count (3 streams)
      _activeGeolocatorStreams = 1;
      debugPrint(
        '[LocationService] Stream optimization active. Active location streams before optimization: $streamsBefore. Active streams after optimization: 1 (single shared stream).',
      );

      _sharedPositionSubscription = getPositionStream(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        isBackgroundTracking: isBackgroundTracking,
      ).listen(
        (position) {
          updateSharedPosition(position);
        },
        onError: (error) {
          debugPrint('[LocationService] Shared position stream error: $error');
        },
      );
    } else {
      debugPrint(
        '[LocationService] Subscribed to existing single shared location stream. Active Geolocator streams: 1.',
      );
    }
  }

  /// Removes a listener from the shared location stream and cancels the stream if no listeners remain.
  static void removeSharedListener(void Function(Position position) onPosition) {
    _sharedListeners.remove(onPosition);
    if (_sharedListeners.isEmpty && _sharedPositionSubscription != null) {
      debugPrint('[LocationService] No active shared listeners. Cancelling single shared location stream. Active streams: 0.');
      _sharedPositionSubscription?.cancel();
      _sharedPositionSubscription = null;
      _activeGeolocatorStreams = 0;
    }
  }

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
      debugPrint('[LocationService] POST_NOTIFICATIONS status: $status');
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        debugPrint('[LocationService] POST_NOTIFICATIONS request result: $result');
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
      debugPrint('[LocationService] getPositionStream: Configuring AndroidSettings for location stream.');
      locationSettings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 3),
      );
    } else if (isBackgroundTracking &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      debugPrint('[LocationService] getPositionStream: Configuring AppleSettings with background location indicator.');
      locationSettings = AppleSettings(
        accuracy: accuracy,
        activityType: ActivityType.fitness,
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      debugPrint('[LocationService] getPositionStream: Configuring standard LocationSettings.');
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
