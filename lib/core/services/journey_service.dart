import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/destination_place.dart';
import '../models/journey_history_record.dart';
import '../models/route_result.dart';
import '../router/app_router.dart';
import 'alarm_service.dart';
import 'journey_history_service.dart';
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
}

class JourneyService {
  JourneyService({RouteService? routeService, this.alarmService})
      : _routeService = routeService ?? RouteService();

  static final JourneyService instance = JourneyService();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  ActiveJourneyState? get currentJourney => activeJourneyNotifier.value;
  bool get hasActiveJourney => activeJourneyNotifier.value != null;

  Future<void> startJourney({
    required DestinationPlace destinationPlace,
    double alarmThresholdMeters = 1000.0,
    bool isVibrationEnabled = true,
  }) async {
    final current = activeJourneyNotifier.value;
    if (current != null &&
        current.destinationPlace.name == destinationPlace.name &&
        current.destinationPlace.latitude == destinationPlace.latitude &&
        current.destinationPlace.longitude == destinationPlace.longitude) {
      return;
    }

    await stopJourney();

    final state = ActiveJourneyState(
      destinationPlace: destinationPlace,
      alarmThresholdMeters: alarmThresholdMeters,
      isVibrationEnabled: isVibrationEnabled,
      startTime: DateTime.now(),
    );

    _hasTriggeredAlarm = false;
    activeJourneyNotifier.value = state;

    await _initPositionStream(state);
  }

  Future<void> stopJourney({String? explicitStatus}) async {
    final state = activeJourneyNotifier.value;
    if (state != null) {
      final endTime = DateTime.now();
      final durationSeconds = endTime.difference(state.startTime).inSeconds;
      final status = explicitStatus ?? (_hasTriggeredAlarm ? 'Completed' : 'Cancelled');
      final routeRes = routeResultNotifier.value;
      final totalDist = routeRes?.distanceMeters ?? 0.0;

      final travelMode = await SettingsService.instance.getTravelMode();

      final record = JourneyHistoryRecord(
        id: '${DateTime.now().millisecondsSinceEpoch}',
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

      unawaited(JourneyHistoryService.instance.addRecord(record));
    }

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _hasTriggeredAlarm = false;
    activeJourneyNotifier.value = null;
    currentPositionNotifier.value = null;
    routeResultNotifier.value = null;
    try {
      final alarm = alarmService ?? AlarmService.instance;
      await alarm.stopAlarm();
    } catch (e) {
      debugPrint('Error stopping alarm in JourneyService: $e');
    }
  }

  Future<void> _initPositionStream(ActiveJourneyState state) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final isBgTracking = await SettingsService.instance.isBackgroundTracking();

      final permission = await LocationService.checkAndRequestPermission(
        isBackground: isBgTracking,
      );
      if (permission != LocationPermissionState.granted) return;

      final isHighGps = await SettingsService.instance.isHighAccuracyGps();

      if (isBgTracking) {
        await LocationService.requestNotificationPermission();
      }

      final initialPos = await LocationService.getCurrentPosition();
      if (initialPos != null) {
        _onLocationUpdated(initialPos, state);
      }

      _positionSubscription = LocationService.getPositionStream(
        accuracy: isHighGps ? LocationAccuracy.high : LocationAccuracy.medium,
        distanceFilter: 10,
        isBackgroundTracking: isBgTracking,
      ).listen(
        (position) {
          _onLocationUpdated(position, state);
        },
        onError: (error) {
          debugPrint('JourneyService position stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error starting JourneyService position stream: $e');
    }
  }

  Future<void> _onLocationUpdated(
    Position position,
    ActiveJourneyState state,
  ) async {
    if (activeJourneyNotifier.value != state) {
      return;
    }

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

    if (!_hasTriggeredAlarm && directDistanceMeters <= state.alarmThresholdMeters) {
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

    try {
      final route = await _routeService.calculateRoute(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        destinationLatitude: state.destinationPlace.latitude,
        destinationLongitude: state.destinationPlace.longitude,
      );
      if (activeJourneyNotifier.value == state) {
        routeResultNotifier.value = route;
      }
    } catch (e) {
      debugPrint('JourneyService live route update error: $e');
    }
  }
}
