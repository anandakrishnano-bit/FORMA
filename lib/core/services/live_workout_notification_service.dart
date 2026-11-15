import 'dart:io';
import 'package:flutter/services.dart';

/// Service managing native Android 16 (API 36+) promoted live notifications
/// for active workout tracking with graceful fallback for earlier Android versions.
class LiveWorkoutNotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.forma.app/live_updates');

  static final LiveWorkoutNotificationService _instance =
      LiveWorkoutNotificationService._internal();
  factory LiveWorkoutNotificationService() => _instance;
  LiveWorkoutNotificationService._internal();

  bool _isActive = false;
  bool get isActive => _isActive;

  Future<void> startWorkoutLiveUpdate({
    required String title,
    required String exerciseName,
    required double progressFraction,
    required int elapsedSeconds,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startWorkoutLiveUpdate', {
        'title': title,
        'exerciseName': exerciseName,
        'progressFraction': progressFraction.clamp(0.0, 1.0),
        'elapsedSeconds': elapsedSeconds,
      });
      _isActive = true;
    } catch (_) {}
  }

  Future<void> updateWorkoutLiveUpdate({
    required String title,
    required String exerciseName,
    required double progressFraction,
    required int elapsedSeconds,
  }) async {
    if (!Platform.isAndroid || !_isActive) return;
    try {
      await _channel.invokeMethod('updateWorkoutLiveUpdate', {
        'title': title,
        'exerciseName': exerciseName,
        'progressFraction': progressFraction.clamp(0.0, 1.0),
        'elapsedSeconds': elapsedSeconds,
      });
    } catch (_) {}
  }

  Future<void> stopWorkoutLiveUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopWorkoutLiveUpdate');
      _isActive = false;
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getDiagnostics() async {
    if (!Platform.isAndroid) {
      return {'supported': false, 'reason': 'Not an Android device'};
    }
    try {
      final res =
          await _channel.invokeMapMethod<String, dynamic>('getDiagnostics');
      return res ?? {};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
