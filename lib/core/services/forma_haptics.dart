import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Android 16 & Modern Tactile Haptic System for FORMA.
///
/// Features subtle, contextual feedback:
/// - Selection: bottom nav tabs, date pickers, segmented pills
/// - Light impact: keypad digit tap, minor toggle
/// - Medium impact: rest timer tick, exercise checkmark
/// - Heavy impact: completed set, completed workout, budget save
/// - Success / Warning / Error vibration patterns
class FormaHaptics {
  static const String _keyHapticsEnabled = 'forma_haptics_enabled';
  static bool _isEnabled = true;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_keyHapticsEnabled) ?? true;
      _initialized = true;
    } catch (_) {
      _isEnabled = true;
    }
  }

  static bool get isEnabled => _isEnabled;

  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHapticsEnabled, enabled);
    } catch (_) {}
  }

  /// Gentle click for tabs, date selection, or picker rolls.
  static void selection() {
    if (!_isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Light tactile pop for keypad buttons or toggles.
  static void lightImpact() {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Medium feedback for timer triggers, portion selection, set checks.
  static void mediumImpact() {
    if (!_isEnabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Heavy celebratory punch for workout completion or goal reached.
  static void heavyImpact() {
    if (!_isEnabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Multi-pulse success pattern.
  static void success() {
    if (!_isEnabled) return;
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 90), () {
      if (_isEnabled) HapticFeedback.lightImpact();
    });
  }

  /// Warning / Error double-pulse alert.
  static void error() {
    if (!_isEnabled) return;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_isEnabled) HapticFeedback.mediumImpact();
    });
  }
}
