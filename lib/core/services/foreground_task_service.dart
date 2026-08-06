import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination_place.dart';
import '../models/journey_history_record.dart';
import 'alarm_service.dart';
import 'destination_search_service.dart';
import 'journey_history_service.dart';
import 'journey_notification_service.dart';
import 'journey_service.dart';
import 'settings_service.dart';

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(JourneyTaskHandler());
}

class JourneyTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _bgPositionSubscription;
  bool _hasTriggeredAlarm = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[ForegroundTaskHandler] TaskHandler onStart in background isolate at $timestamp.');
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(JourneyService.keyActiveJourneyState);
      if (raw == null || raw.isEmpty) {
        debugPrint('[ForegroundTaskHandler] No saved active journey state found in background isolate.');
        return;
      }

      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      final state = ActiveJourneyState.fromJson(jsonMap);
      debugPrint('[ForegroundTaskHandler] Background TaskHandler monitoring destination: ${state.destinationPlace.name}');

      _hasTriggeredAlarm = false;

      final locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 3),
      );

      _bgPositionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) async {
          final dest = state.destinationPlace;
          final directDistanceMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            dest.latitude,
            dest.longitude,
          );

          final notifTitle = 'Heading to ${dest.name}';
          final formattedDist = DestinationSearchService.formatDistance(directDistanceMeters);
          final notifText = '$formattedDist • Tracking location';

          await FlutterForegroundTask.updateService(
            notificationTitle: notifTitle,
            notificationText: notifText,
          );

          FlutterForegroundTask.sendDataToMain({
            'type': 'location_update',
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'directDistanceMeters': directDistanceMeters,
          });

          if (!_hasTriggeredAlarm &&
              (position.accuracy <= 0 || position.accuracy <= 200.0) &&
              directDistanceMeters <= state.alarmThresholdMeters) {
            debugPrint('[ForegroundTaskHandler] ALARM TRIGGERED IN BACKGROUND ISOLATE! Distance: ${directDistanceMeters.toStringAsFixed(1)}m');
            _hasTriggeredAlarm = true;

            try {
              await AlarmService.instance.startAlarm(
                isVibrationEnabled: state.isVibrationEnabled,
              );
            } catch (e) {
              debugPrint('[ForegroundTaskHandler] Error triggering alarm in background: $e');
            }

            FlutterForegroundTask.sendDataToMain({
              'type': 'alarm_triggered',
              'destination': dest.toJson(),
            });
          }
        },
        onError: (error) {
          debugPrint('[ForegroundTaskHandler] Background location stream error: $error');
        },
      );
      debugPrint('[ForegroundTaskHandler] Background position stream initialized successfully.');
    } catch (e) {
      debugPrint('[ForegroundTaskHandler] Error in background TaskHandler onStart: $e');
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[ForegroundTaskHandler] Background TaskHandler destroyed at $timestamp. Handling active journey cleanup.');
    await _handleRecentAppsDismissal();
  }

  @override
  void onNotificationPressed() {
    debugPrint('[ForegroundTaskHandler] Persistent notification tapped. Launching app...');
    FlutterForegroundTask.launchApp();
  }

  Future<void> _handleRecentAppsDismissal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(JourneyService.keyActiveJourneyState);
      if (raw != null && raw.isNotEmpty) {
        await prefs.remove(JourneyService.keyActiveJourneyState);
        final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
        final state = ActiveJourneyState.fromJson(jsonMap);
        final endTime = DateTime.now();
        final durationSeconds = endTime.difference(state.startTime).inSeconds;
        final travelMode = await SettingsService.instance.getTravelMode();

        final record = JourneyHistoryRecord(
          id: JourneyHistoryRecord.generateUniqueId(),
          destinationName: state.destinationPlace.name,
          destinationAddress: state.destinationPlace.address,
          destinationLatitude: state.destinationPlace.latitude,
          destinationLongitude: state.destinationPlace.longitude,
          startTime: state.startTime,
          endTime: endTime,
          totalDurationSeconds: durationSeconds,
          totalDistanceMeters: 0.0,
          alarmThresholdMeters: state.alarmThresholdMeters,
          travelMode: travelMode,
          status: 'Cancelled',
        );

        debugPrint(
          '[ForegroundTaskHandler] Saving JourneyHistoryRecord with final status: "Cancelled" for destination: "${state.destinationPlace.name}"',
        );
        await JourneyHistoryService.instance.addRecord(record);
      } else {
        debugPrint(
          '[ForegroundTaskHandler] Active journey already cleared or saved. Skipping duplicate record creation.',
        );
      }
    } catch (e) {
      debugPrint('[ForegroundTaskHandler] Error clearing active journey state on task removal: $e');
    }

    try {
      await AlarmService.instance.stopAlarm();
    } catch (e) {
      debugPrint('[ForegroundTaskHandler] Error stopping alarm on task removal: $e');
    }

    await _bgPositionSubscription?.cancel();
    _bgPositionSubscription = null;

    try {
      await FlutterForegroundTask.stopService();
      debugPrint('[ForegroundTaskHandler] Foreground service stopped after task removal.');
    } catch (e) {
      debugPrint('[ForegroundTaskHandler] Error stopping service after task removal: $e');
    }
  }
}

class ForegroundTaskService {
  ForegroundTaskService._();

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'norivo_active_journey_channel',
        channelName: 'Norivo Active Journey',
        channelDescription:
            'Displays active journey status and background location tracking.',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
  }

  static void attachTaskDataCallback(void Function(Object data) callback) {
    try {
      FlutterForegroundTask.addTaskDataCallback(callback);
    } catch (e) {
      debugPrint('Error attaching task data callback: $e');
    }
  }

  static void detachTaskDataCallback(void Function(Object data) callback) {
    try {
      FlutterForegroundTask.removeTaskDataCallback(callback);
    } catch (e) {
      debugPrint('Error detaching task data callback: $e');
    }
  }

  static Future<void> startService({
    required DestinationPlace destination,
    double? initialDistanceMeters,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await init();

      final title = JourneyNotificationService.buildTitle(destination);
      final text = initialDistanceMeters != null && initialDistanceMeters > 0
          ? '${DestinationSearchService.formatDistance(initialDistanceMeters)} • Tracking location'
          : 'Tracking location in background to wake you up before arrival.';

      final isRunning = await FlutterForegroundTask.isRunningService
          .timeout(const Duration(milliseconds: 200), onTimeout: () => false);
      if (isRunning) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        ).timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => throw TimeoutException('ForegroundTask updateService timeout'),
        );
        return;
      }

      await FlutterForegroundTask.startService(
        serviceId: 1001,
        notificationTitle: title,
        notificationText: text,
        callback: _startCallback,
      ).timeout(
        const Duration(milliseconds: 200),
        onTimeout: () => throw TimeoutException('ForegroundTask startService timeout'),
      );
    } catch (e) {
      debugPrint('ForegroundTaskService startService error: $e');
    }
  }

  static Future<void> updateNotification({
    required String title,
    required String text,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final isRunning = await FlutterForegroundTask.isRunningService
          .timeout(const Duration(milliseconds: 200), onTimeout: () => false);
      if (isRunning) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        ).timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => throw TimeoutException('ForegroundTask updateNotification timeout'),
        );
      }
    } catch (e) {
      debugPrint('ForegroundTaskService updateNotification error: $e');
    }
  }

  static Future<void> stopService() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final isRunning = await FlutterForegroundTask.isRunningService
          .timeout(const Duration(milliseconds: 200), onTimeout: () => false);
      if (isRunning) {
        await FlutterForegroundTask.stopService().timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => throw TimeoutException('ForegroundTask stopService timeout'),
        );
      }
    } catch (e) {
      debugPrint('ForegroundTaskService stopService error: $e');
    }
  }
}
