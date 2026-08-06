import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination_place.dart';
import '../models/journey_history_record.dart';
import '../models/route_result.dart';
import '../router/app_router.dart';
import 'alarm_service.dart';
import 'foreground_task_service.dart';
import 'journey_history_service.dart';
import 'journey_notification_service.dart';
import 'location_service.dart';
import 'route_service.dart';
import 'settings_service.dart';

class ActiveJourneyState {
  const ActiveJourneyState({
    required this.destinationPlace,
    required this.alarmThresholdMeters,
    required this.isVibrationEnabled,
    required this.startTime,
  });

  final DestinationPlace destinationPlace;
  final double alarmThresholdMeters;
  final bool isVibrationEnabled;
  final DateTime startTime;

  Map<String, dynamic> toJson() {
    return {
      'destinationPlace': destinationPlace.toJson(),
      'alarmThresholdMeters': alarmThresholdMeters,
      'isVibrationEnabled': isVibrationEnabled,
      'startTime': startTime.toIso8601String(),
    };
  }

  factory ActiveJourneyState.fromJson(Map<String, dynamic> json) {
    return ActiveJourneyState(
      destinationPlace: DestinationPlace.fromJson(
        json['destinationPlace'] as Map<String, dynamic>,
      ),
      alarmThresholdMeters: (json['alarmThresholdMeters'] as num).toDouble(),
      isVibrationEnabled: json['isVibrationEnabled'] as bool? ?? true,
      startTime: DateTime.parse(json['startTime'] as String),
    );
  }
}

class JourneyService {
  JourneyService({RouteService? routeService, this.alarmService})
      : _routeService = routeService ?? RouteService();

  static JourneyService instance = JourneyService();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const String keyActiveJourneyState = 'norivo_active_journey_state';



  final RouteService _routeService;
  final AlarmService? alarmService;

  final ValueNotifier<ActiveJourneyState?> activeJourneyNotifier =
      ValueNotifier<ActiveJourneyState?>(null);

  final ValueNotifier<Position?> currentPositionNotifier =
      ValueNotifier<Position?>(null);

  final ValueNotifier<RouteResult?> routeResultNotifier =
      ValueNotifier<RouteResult?>(null);

  StreamSubscription<Position>? _positionSubscription;
  bool _hasTriggeredAlarm = false;
  bool _isCalculatingRoute = false;
  DateTime? _lastRouteCalculationTime;
  DestinationPlace? _lastRouteDestination;

  static const Duration _routeCooldownDuration = Duration(seconds: 15);
  static const double _rerouteThresholdMeters = 150.0;

  ActiveJourneyState? get currentJourney => activeJourneyNotifier.value;
  bool get hasActiveJourney => activeJourneyNotifier.value != null;

  Future<ActiveJourneyState?> restoreActiveJourney() async {
    if (hasActiveJourney) return activeJourneyNotifier.value;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(keyActiveJourneyState);
      if (raw == null || raw.isEmpty) {
        debugPrint('[JourneyService] restoreActiveJourney: No active journey found in SharedPreferences after reload.');
        return null;
      }

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final state = ActiveJourneyState.fromJson(json);
      debugPrint('[JourneyService] Restoring saved active journey state for: ${state.destinationPlace.name}');

      _hasTriggeredAlarm = false;
      activeJourneyNotifier.value = state;

      await _initPositionStream(state);
      return state;
    } catch (e) {
      debugPrint('Error restoring active journey: $e');
      return null;
    }
  }

  Future<void> startJourney({
    required DestinationPlace destinationPlace,
    double alarmThresholdMeters = 1000.0,
    bool isVibrationEnabled = true,
  }) async {
    debugPrint('[JourneyService] startJourney() invoked for destination: ${destinationPlace.name} (${destinationPlace.latitude}, ${destinationPlace.longitude})');
    final current = activeJourneyNotifier.value;
    if (current != null &&
        (current.destinationPlace.latitude - destinationPlace.latitude).abs() < 0.0001 &&
        (current.destinationPlace.longitude - destinationPlace.longitude).abs() < 0.0001) {
      debugPrint('[JourneyService] Journey already active for ${destinationPlace.name}. Skipping duplicate start.');
      return;
    }

    if (current != null) {
      debugPrint('[JourneyService] Stopping existing journey before starting new one.');
      await stopJourney(explicitStatus: 'Replaced');
    }

    final state = ActiveJourneyState(
      destinationPlace: destinationPlace,
      alarmThresholdMeters: alarmThresholdMeters,
      isVibrationEnabled: isVibrationEnabled,
      startTime: DateTime.now(),
    );

    _hasTriggeredAlarm = false;
    activeJourneyNotifier.value = state;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyActiveJourneyState, jsonEncode(state.toJson()));
      debugPrint('[JourneyService] Saved active journey state to local storage for: ${destinationPlace.name}');
    } catch (e) {
      debugPrint('Error persisting active journey state: $e');
    }

    await _initPositionStream(state);
  }

  bool _isStoppingJourney = false;

  Future<JourneyHistoryRecord?> stopJourney({String? explicitStatus}) async {
    if (_isStoppingJourney) {
      debugPrint(
        '[JourneyService] stopJourney() already in progress. Skipping duplicate call.',
      );
      return null;
    }
    _isStoppingJourney = true;

    try {
      final state = activeJourneyNotifier.value;
      debugPrint(
        '[JourneyService] stopJourney() invoked. ExplicitStatus: $explicitStatus, ActiveState: ${state?.destinationPlace.name}',
      );
      activeJourneyNotifier.value = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(keyActiveJourneyState);

      if (raw != null && raw.isNotEmpty) {
        try {
          await prefs.remove(keyActiveJourneyState);
          debugPrint(
            '[JourneyService] Cleared saved active journey state from local storage before service stop.',
          );
        } catch (e) {
          debugPrint('Error clearing active journey state in stopJourney: $e');
        }
      }

      JourneyHistoryRecord? savedRecord;

      if (state != null && raw != null && raw.isNotEmpty) {
        final endTime = DateTime.now();
        final durationSeconds = endTime.difference(state.startTime).inSeconds;
        final status = (explicitStatus == 'Completed')
            ? 'Completed'
            : ((explicitStatus == 'Cancelled' || explicitStatus == 'Replaced')
                ? 'Cancelled'
                : (_hasTriggeredAlarm ? 'Completed' : 'Cancelled'));
        final routeRes = routeResultNotifier.value;
        final totalDist = routeRes?.distanceMeters ?? 0.0;

        final travelMode = await SettingsService.instance.getTravelMode();

        final recordId = JourneyHistoryRecord.generateUniqueId();
        debugPrint(
          '[JourneyService] Saving JourneyHistoryRecord: id=$recordId, status="$status", destination="${state.destinationPlace.name}" (explicitStatus: $explicitStatus, _hasTriggeredAlarm: $_hasTriggeredAlarm)',
        );

        savedRecord = JourneyHistoryRecord(
          id: recordId,
          destinationName: state.destinationPlace.name,
          destinationAddress: state.destinationPlace.address,
          destinationLatitude: state.destinationPlace.latitude,
          destinationLongitude: state.destinationPlace.longitude,
          startTime: state.startTime,
          endTime: endTime,
          totalDurationSeconds: durationSeconds,
          totalDistanceMeters: totalDist,
          alarmThresholdMeters: state.alarmThresholdMeters,
          travelMode: travelMode,
          status: status,
        );

        await JourneyHistoryService.instance.addRecord(savedRecord);
      }

      debugPrint(
        '[JourneyService] Cancelling position subscription and clearing active journey state.',
      );
      ForegroundTaskService.detachTaskDataCallback(_onReceiveTaskData);
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _hasTriggeredAlarm = false;
      _isCalculatingRoute = false;
      _lastRouteCalculationTime = null;
      _lastRouteDestination = null;
      currentPositionNotifier.value = null;
      routeResultNotifier.value = null;
      debugPrint(
        '[JourneyService] In-memory state cleared. All journeyNotifiers reset to null.',
      );

      try {
        await ForegroundTaskService.stopService();
        final alarm = alarmService ?? AlarmService.instance;
        await alarm.stopAlarm();
      } catch (e) {
        debugPrint('Error stopping alarm in JourneyService: $e');
      }

      return savedRecord;
    } finally {
      _isStoppingJourney = false;
    }
  }

  Future<void> _initPositionStream(ActiveJourneyState state) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[JourneyService] _initPositionStream - locationServiceEnabled: $serviceEnabled');
      if (!serviceEnabled) return;

      final isBgTracking = await SettingsService.instance.isBackgroundTracking();
      debugPrint('[JourneyService] _initPositionStream - isBackgroundTracking setting: $isBgTracking');

      final permission = await LocationService.checkAndRequestPermission(
        isBackground: isBgTracking,
      );
      debugPrint('[JourneyService] _initPositionStream - permission: $permission');
      if (permission != LocationPermissionState.granted) return;

      final isHighGps = await SettingsService.instance.isHighAccuracyGps();
      debugPrint('[JourneyService] _initPositionStream - isHighAccuracyGps: $isHighGps');

      final initialPos = await LocationService.getCurrentPosition();
      debugPrint('[JourneyService] Initial position fetched: ${initialPos?.latitude}, ${initialPos?.longitude}, accuracy: ${initialPos?.accuracy}');
      if (initialPos != null) {
        _onLocationUpdated(initialPos, state);
      }

      if (defaultTargetPlatform == TargetPlatform.android && isBgTracking) {
        debugPrint('[JourneyService] Requesting notification permission and starting ForegroundTaskService...');
        await LocationService.requestNotificationPermission();
        final dist = initialPos != null
            ? Geolocator.distanceBetween(
                initialPos.latitude,
                initialPos.longitude,
                state.destinationPlace.latitude,
                state.destinationPlace.longitude,
              )
            : null;
        await ForegroundTaskService.startService(
          destination: state.destinationPlace,
          initialDistanceMeters: dist,
        );

        ForegroundTaskService.attachTaskDataCallback(_onReceiveTaskData);
        debugPrint('[LocationService] Stream optimization active. Active location streams before optimization: 3. Active streams after optimization: 1 (owned by background TaskHandler).');
        debugPrint('[JourneyService] Dedicated background TaskHandler owns position stream. Main UI attached to task data callback.');
        return;
      }

      debugPrint('[JourneyService] Initializing single shared Geolocator position stream...');

      LocationService.listenToSharedLocation(
        accuracy: isHighGps ? LocationAccuracy.high : LocationAccuracy.medium,
        distanceFilter: 10,
        isBackgroundTracking: isBgTracking,
        onPosition: (position) {
          _onLocationUpdated(position, state);
        },
      );
      debugPrint('[JourneyService] Subscribed to single shared position stream successfully.');
    } catch (e) {
      debugPrint('Error starting JourneyService position stream: $e');
    }
  }

  bool _shouldRecalculateRoute(Position position, ActiveJourneyState state) {
    final cachedRoute = routeResultNotifier.value;

    if (cachedRoute == null) {
      debugPrint('[JourneyService] Reroute triggered due to missing route cache.');
      return true;
    }

    if (_lastRouteDestination == null ||
        (_lastRouteDestination!.latitude - state.destinationPlace.latitude).abs() > 0.0001 ||
        (_lastRouteDestination!.longitude - state.destinationPlace.longitude).abs() > 0.0001) {
      debugPrint('[JourneyService] Reroute triggered due to destination change.');
      return true;
    }

    final now = DateTime.now();
    if (_lastRouteCalculationTime != null) {
      final elapsed = now.difference(_lastRouteCalculationTime!);
      if (elapsed < _routeCooldownDuration) {
        final remainingSec = (_routeCooldownDuration - elapsed).inSeconds;
        debugPrint('[JourneyService] Route request skipped (cooldown active: ${remainingSec}s remaining).');
        debugPrint('[JourneyService] Route cache used. Distance: ${cachedRoute.distanceMeters.toStringAsFixed(1)}m');
        return false;
      }
    }

    final polyline = cachedRoute.polyline;
    if (polyline.isNotEmpty) {
      double minPolylineDistance = double.infinity;
      for (final pt in polyline) {
        final dist = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          pt.latitude,
          pt.longitude,
        );
        if (dist < minPolylineDistance) {
          minPolylineDistance = dist;
        }
      }

      if (minPolylineDistance > _rerouteThresholdMeters) {
        debugPrint('[JourneyService] Reroute triggered due to deviation from route (off-route dist: ${minPolylineDistance.toStringAsFixed(1)}m > ${_rerouteThresholdMeters}m).');
        return true;
      } else {
        debugPrint('[JourneyService] Route request skipped (user is on route, off-route dist: ${minPolylineDistance.toStringAsFixed(1)}m).');
        debugPrint('[JourneyService] Route cache used. Distance: ${cachedRoute.distanceMeters.toStringAsFixed(1)}m');
        return false;
      }
    }

    debugPrint('[JourneyService] Route cache used. Distance: ${cachedRoute.distanceMeters.toStringAsFixed(1)}m');
    return false;
  }

  Future<void> _onLocationUpdated(
    Position position,
    ActiveJourneyState state,
  ) async {
    if (activeJourneyNotifier.value != state) {
      return;
    }

    LocationService.updateSharedPosition(position);
    currentPositionNotifier.value = position;

    final dest = state.destinationPlace;
    final directDistanceMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      dest.latitude,
      dest.longitude,
    );

    if (activeJourneyNotifier.value != state) {
      return;
    }

    if (!_hasTriggeredAlarm &&
        (position.accuracy <= 0 || position.accuracy <= 200.0) &&
        directDistanceMeters <= state.alarmThresholdMeters) {
      debugPrint('[JourneyService] ALARM TRIGGERED! Distance: ${directDistanceMeters.toStringAsFixed(1)}m, Threshold: ${state.alarmThresholdMeters}m, Accuracy: ${position.accuracy}m');
      _hasTriggeredAlarm = true;
      await AlarmService.instance.startAlarm(
        isVibrationEnabled: state.isVibrationEnabled,
      );
      if (activeJourneyNotifier.value == state) {
        navigatorKey.currentState?.pushNamed(
          AppRouter.alarmRinging,
          arguments: dest,
        );
      }
      return;
    }

    if (_isCalculatingRoute) {
      debugPrint('[JourneyService] Route calculation request already in progress. Skipping.');
    } else if (_shouldRecalculateRoute(position, state)) {
      _isCalculatingRoute = true;
      try {
        final route = await _routeService.calculateRoute(
          startLatitude: position.latitude,
          startLongitude: position.longitude,
          destinationLatitude: state.destinationPlace.latitude,
          destinationLongitude: state.destinationPlace.longitude,
        );
        if (activeJourneyNotifier.value == state) {
          routeResultNotifier.value = route;
          _lastRouteCalculationTime = DateTime.now();
          _lastRouteDestination = state.destinationPlace;
        }
      } catch (e) {
        debugPrint('JourneyService live route update error: $e');
      } finally {
        _isCalculatingRoute = false;
      }
    }

    if (activeJourneyNotifier.value == state) {
      final routeRes = routeResultNotifier.value;
      final durationSecs = routeRes?.durationSeconds ?? (directDistanceMeters / 13.89);
      final notifTitle = JourneyNotificationService.buildTitle(dest);
      final notifText = JourneyNotificationService.buildContent(
        distanceMeters: directDistanceMeters,
        durationSeconds: durationSecs,
        isNearDestination: directDistanceMeters <= state.alarmThresholdMeters,
      );
      unawaited(ForegroundTaskService.updateNotification(
        title: notifTitle,
        text: notifText,
      ));
    }
  }

  void _onReceiveTaskData(Object data) {
    if (data is! Map) return;

    final state = activeJourneyNotifier.value;
    if (state == null) return;

    final type = data['type'] as String?;
    if (type == 'location_update') {
      final lat = (data['latitude'] as num).toDouble();
      final lng = (data['longitude'] as num).toDouble();
      final accuracy = (data['accuracy'] as num).toDouble();
      final pos = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: accuracy,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      _onLocationUpdated(pos, state);
    } else if (type == 'alarm_triggered') {
      if (!_hasTriggeredAlarm) {
        _hasTriggeredAlarm = true;
        navigatorKey.currentState?.pushNamed(
          AppRouter.alarmRinging,
          arguments: state.destinationPlace,
        );
      }
    }
  }
}
