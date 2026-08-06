import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'settings_service.dart';

class AlarmService {
  AlarmService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  static final AlarmService instance = AlarmService();

  final AudioPlayer _player;
  Timer? _vibrationTimer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Starts playing looping alarm sound and vibrating the device.
  Future<void> startAlarm({bool? isVibrationEnabled}) async {
    debugPrint('[AlarmService] startAlarm() invoked. isPlaying=$_isPlaying, isVibrationEnabled=$isVibrationEnabled');
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        final audioContext = AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gain,
          ),
        );

        await AudioPlayer.global.setAudioContext(audioContext);
        await _player.setAudioContext(audioContext);
      }

      await _player.setReleaseMode(ReleaseMode.loop);
      final volume = await SettingsService.instance.getAlarmVolume();
      await _player.setVolume(volume);
      await _player.play(AssetSource('sounds/alarm.wav'));
    } catch (e) {
      try {
        await _player.play(
          UrlSource(
            'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg',
          ),
        );
      } catch (_) {}
    }

    try {
      final shouldVibrate = isVibrationEnabled ?? await SettingsService.instance.isVibrationEnabled();
      if (shouldVibrate && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(pattern: [500, 500, 500, 500], repeat: 0);
        } else {
          _vibrationTimer?.cancel();
          _vibrationTimer = Timer.periodic(
            const Duration(milliseconds: 1000),
            (_) => HapticFeedback.vibrate(),
          );
        }
      }
    } catch (e) {
      debugPrint('[AlarmService] Error starting vibration: $e');
      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(
        const Duration(milliseconds: 1000),
        (_) => HapticFeedback.vibrate(),
      );
    }
  }

  /// Stops the alarm sound and vibration.
  Future<void> stopAlarm() async {
    debugPrint('[AlarmService] stopAlarm() invoked. Stopping playback and vibration...');
    _isPlaying = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      await Vibration.cancel();
      debugPrint('[AlarmService] Vibration cancelled.');
    } catch (e) {
      debugPrint('[AlarmService] Error cancelling vibration: $e');
    }

    try {
      await _player.stop();
      debugPrint('[AlarmService] AudioPlayer stopped.');
    } catch (e) {
      debugPrint('[AlarmService] Error stopping audio player: $e');
    }
  }
}
