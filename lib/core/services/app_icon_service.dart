import 'package:flutter/services.dart';
import 'package:forma/core/services/app_logger.dart';

/// Service managing Dynamic Android Launcher App Icons via activity-aliases.
class AppIconService {
  static const MethodChannel _channel = MethodChannel('com.forma.app/app_icon');

  static final AppIconService _instance = AppIconService._internal();
  factory AppIconService() => _instance;
  AppIconService._internal();

  /// Supported icon variants: 'Default', 'Chest', 'Back', 'Legs', 'Arms', 'Rest'
  static const List<String> supportedIcons = [
    'Default',
    'Chest',
    'Back',
    'Legs',
    'Arms',
    'Rest',
  ];

  /// Switches active Android launcher icon via activity-alias.
  Future<bool> setAppIcon(String iconName) async {
    try {
      final success = await _channel.invokeMethod<bool>('setAppIcon', {
        'iconName': iconName,
      });
      AppLogger.success('APP_ICON', 'Switched launcher icon to: $iconName');
      return success ?? false;
    } catch (e) {
      AppLogger.warn('APP_ICON', 'Failed to change launcher icon: $e');
      return false;
    }
  }

  /// Retrieves the currently enabled launcher icon alias.
  Future<String> getCurrentAppIcon() async {
    try {
      final current = await _channel.invokeMethod<String>('getCurrentAppIcon');
      return current ?? 'Default';
    } catch (e) {
      return 'Default';
    }
  }

  /// Automatically picks the icon based on today's target muscle or split type.
  Future<bool> applyAutoWorkoutAppIcon(String? workoutCategory) async {
    if (workoutCategory == null || workoutCategory.isEmpty) {
      return setAppIcon('Default');
    }
    final lower = workoutCategory.toLowerCase();
    if (lower.contains('chest') || lower.contains('push')) {
      return setAppIcon('Chest');
    } else if (lower.contains('back') || lower.contains('pull')) {
      return setAppIcon('Back');
    } else if (lower.contains('leg') ||
        lower.contains('quad') ||
        lower.contains('hamstring') ||
        lower.contains('glute')) {
      return setAppIcon('Legs');
    } else if (lower.contains('arm') ||
        lower.contains('bicep') ||
        lower.contains('tricep')) {
      return setAppIcon('Arms');
    } else if (lower.contains('rest') || lower.contains('recovery')) {
      return setAppIcon('Rest');
    }
    return setAppIcon('Default');
  }
}
