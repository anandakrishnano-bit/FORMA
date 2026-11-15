import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Health Connect Data Model for FORMA.
class DailyHealthMetrics {
  final int steps;
  final double activeCalories;
  final double totalCaloriesBurned;
  final double? heartRateBpm;
  final double distanceMeters;
  final bool isAuthorized;
  final DateTime timestamp;

  const DailyHealthMetrics({
    this.steps = 0,
    this.activeCalories = 0.0,
    this.totalCaloriesBurned = 0.0,
    this.heartRateBpm,
    this.distanceMeters = 0.0,
    this.isAuthorized = false,
    required this.timestamp,
  });

  DailyHealthMetrics copyWith({
    int? steps,
    double? activeCalories,
    double? totalCaloriesBurned,
    double? heartRateBpm,
    double? distanceMeters,
    bool? isAuthorized,
    DateTime? timestamp,
  }) {
    return DailyHealthMetrics(
      steps: steps ?? this.steps,
      activeCalories: activeCalories ?? this.activeCalories,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      isAuthorized: isAuthorized ?? this.isAuthorized,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Singleton service wrapping Google Health Connect on Android.
class HealthConnectService {
  static final HealthConnectService _instance =
      HealthConnectService._internal();
  factory HealthConnectService() => _instance;
  HealthConnectService._internal();

  final Health _health = Health();
  static const String _prefEnabledKey = 'forma_health_connect_enabled';

  static final List<HealthDataType> _supportedTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.DISTANCE_DELTA,
  ];

  static final List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  /// Initialize Health plugin configuration.
  Future<void> configure() async {
    try {
      await _health.configure();
    } catch (e) {
      debugPrint('[HealthConnect] Configure error: $e');
    }
  }

  /// Check whether Health Connect is enabled by user in app settings.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabledKey) ?? false;
  }

  /// Set enabled flag.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabledKey, enabled);
  }

  /// Request permissions from Google Health Connect.
  Future<bool> requestPermissions() async {
    try {
      await configure();
      final granted = await _health.requestAuthorization(
        _supportedTypes,
        permissions: _permissions,
      );
      if (granted) {
        await setEnabled(true);
      }
      return granted;
    } catch (e) {
      debugPrint('[HealthConnect] Authorization request failed: $e');
      return false;
    }
  }

  /// Check if permissions are currently active.
  Future<bool> hasPermissions() async {
    try {
      final hasPerm = await _health.hasPermissions(_supportedTypes,
          permissions: _permissions);
      return hasPerm ?? false;
    } catch (e) {
      debugPrint('[HealthConnect] hasPermissions error: $e');
      return false;
    }
  }

  /// Revoke / disconnect Health Connect from FORMA.
  Future<void> disconnect() async {
    await setEnabled(false);
  }

  /// Check Health Connect SDK installation / availability status on device.
  Future<HealthConnectSdkStatus?> getSdkStatus() async {
    try {
      await configure();
      return await _health.getHealthConnectSdkStatus();
    } catch (e) {
      debugPrint('[HealthConnect] SDK status error: $e');
      return null;
    }
  }

  /// Query granular permission status per supported health data type.
  Future<Map<HealthDataType, bool>> getGranularPermissions() async {
    final map = <HealthDataType, bool>{};
    for (final type in _supportedTypes) {
      try {
        final has = await _health
            .hasPermissions([type], permissions: [HealthDataAccess.READ]);
        map[type] = has ?? false;
      } catch (_) {
        map[type] = false;
      }
    }
    return map;
  }

  /// Comprehensive diagnostic overview of Google Health Connect integration.
  Future<Map<String, dynamic>> getDiagnostics() async {
    final enabled = await isEnabled();
    final sdkStatus = await getSdkStatus();
    final hasOverall = await hasPermissions();
    final granular = await getGranularPermissions();
    return {
      'enabledInSettings': enabled,
      'sdkStatus': sdkStatus?.name ?? 'unknown',
      'hasOverallPermissions': hasOverall,
      'granular': granular.map((k, v) => MapEntry(k.name, v)),
    };
  }

  /// Fetch actual daily metrics for a given date from Google Health Connect.
  Future<DailyHealthMetrics> fetchDailyMetrics(DateTime date) async {
    final enabled = await isEnabled();
    if (!enabled) {
      return DailyHealthMetrics(isAuthorized: false, timestamp: DateTime.now());
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      await configure();

      // 1. Real Steps Count
      int totalSteps = 0;
      try {
        final steps =
            await _health.getTotalStepsInInterval(startOfDay, endOfDay);
        totalSteps = steps ?? 0;
      } catch (e) {
        debugPrint('[HealthConnect] Error fetching steps: $e');
      }

      // 2. Query Health data points
      double activeCalories = 0.0;
      double totalCalories = 0.0;
      double? latestBpm;
      double distanceMeters = 0.0;

      final dataPoints = await _health.getHealthDataFromTypes(
        types: _supportedTypes,
        startTime: startOfDay,
        endTime: endOfDay,
      );

      for (final p in dataPoints) {
        final val = p.value;
        if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          if (val is NumericHealthValue) {
            activeCalories += val.numericValue.toDouble();
          }
        } else if (p.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          if (val is NumericHealthValue) {
            totalCalories += val.numericValue.toDouble();
          }
        } else if (p.type == HealthDataType.DISTANCE_DELTA) {
          if (val is NumericHealthValue) {
            distanceMeters += val.numericValue.toDouble();
          }
        } else if (p.type == HealthDataType.HEART_RATE) {
          if (val is NumericHealthValue) {
            latestBpm = val.numericValue.toDouble();
          }
        }
      }

      return DailyHealthMetrics(
        steps: totalSteps,
        activeCalories: activeCalories,
        totalCaloriesBurned: totalCalories > 0 ? totalCalories : activeCalories,
        heartRateBpm: latestBpm,
        distanceMeters: distanceMeters,
        isAuthorized: true,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[HealthConnect] Error fetching daily metrics: $e');
      return DailyHealthMetrics(isAuthorized: false, timestamp: DateTime.now());
    }
  }
}

/// Riverpod Provider for Daily Health Connect metrics.
final healthConnectMetricsProvider =
    FutureProvider.family<DailyHealthMetrics, DateTime>((ref, date) async {
  return HealthConnectService().fetchDailyMetrics(date);
});

/// Riverpod Provider to check whether Health Connect is connected.
final healthConnectStatusProvider = FutureProvider<bool>((ref) async {
  return HealthConnectService().isEnabled();
});
