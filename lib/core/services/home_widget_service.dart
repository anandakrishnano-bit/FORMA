import 'package:flutter/services.dart';
import 'package:forma/core/services/app_logger.dart';

/// Platform channel service connecting Flutter state to native Android AppWidgets.
class HomeWidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.forma.app/home_widgets');

  static final HomeWidgetService _instance = HomeWidgetService._internal();
  factory HomeWidgetService() => _instance;
  HomeWidgetService._internal();

  /// Updates the Daily Activity Widget on Android home screen.
  Future<void> updateDailyActivityWidget({
    required String date,
    required int steps,
    String? energyScore,
    required String workoutStatus,
  }) async {
    try {
      await _channel.invokeMethod('updateDailyActivityWidget', {
        'date': date,
        'steps': steps,
        'energyScore': energyScore ?? '--',
        'workoutStatus': workoutStatus,
      });
      AppLogger.info('WIDGET', 'Updated Daily Activity Widget: $steps steps');
    } catch (e) {
      AppLogger.warn('WIDGET', 'Failed to update Daily Activity widget: $e');
    }
  }

  /// Updates the Workout Widget on Android home screen.
  Future<void> updateWorkoutWidget({
    required String workoutName,
    required String workoutSub,
    required bool isActive,
  }) async {
    try {
      await _channel.invokeMethod('updateWorkoutWidget', {
        'workoutName': workoutName,
        'workoutSub': workoutSub,
        'isActive': isActive,
      });
      AppLogger.info('WIDGET', 'Updated Workout Widget: $workoutName');
    } catch (e) {
      AppLogger.warn('WIDGET', 'Failed to update Workout widget: $e');
    }
  }

  /// Updates the Budget Widget on Android home screen.
  Future<void> updateBudgetWidget({
    required String allowance,
    required String details,
    required bool isRedacted,
  }) async {
    try {
      await _channel.invokeMethod('updateBudgetWidget', {
        'allowance': allowance,
        'details': details,
        'isRedacted': isRedacted,
      });
      AppLogger.info(
          'WIDGET', 'Updated Budget Widget: $allowance (redacted=$isRedacted)');
    } catch (e) {
      AppLogger.warn('WIDGET', 'Failed to update Budget widget: $e');
    }
  }
}
