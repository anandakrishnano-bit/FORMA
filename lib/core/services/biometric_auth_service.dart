import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma/core/services/app_logger.dart';

/// Android BiometricPrompt & Local Authentication Service.
///
/// Handles:
/// 1. Hardware capability detection (Fingerprint, Face, Device PIN).
/// 2. Protecting personal expenses and sensitive account settings.
/// 3. Zero biometric data storage (backed strictly by Android Keystore / BiometricPrompt).
class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  static const String _keyAppLockEnabled = 'forma_biometric_app_lock_enabled';
  static const String _keyExpensesLockEnabled =
      'forma_biometric_expenses_lock_enabled';

  /// Checks if the hardware supports biometric authentication.
  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (e) {
      AppLogger.warn(
          'BIOMETRICS', 'Failed to check biometrics availability: $e');
      return false;
    }
  }

  /// Lists available biometric hardware types (fingerprint, face, iris).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      AppLogger.warn('BIOMETRICS', 'Error reading available biometrics: $e');
      return [];
    }
  }

  /// Prompts the user with the native Android BiometricPrompt.
  Future<bool> authenticate({
    required String reason,
    bool sensitiveTransaction = true,
  }) async {
    try {
      final available = await isBiometricsAvailable();
      if (!available) {
        AppLogger.info('BIOMETRICS',
            'Biometrics not available on device, bypassing or using PIN');
        return true;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly:
              false, // Allows device PIN/pattern fallback if biometric fails
          sensitiveTransaction: sensitiveTransaction,
        ),
      );

      if (authenticated) {
        AppLogger.success(
            'BIOMETRICS', 'Biometric authentication succeeded: $reason');
      } else {
        AppLogger.info(
            'BIOMETRICS', 'Biometric authentication cancelled by user');
      }
      return authenticated;
    } on PlatformException catch (e) {
      AppLogger.error('BIOMETRICS',
          'Biometric authentication error: ${e.code} - ${e.message}');
      return false;
    }
  }

  /// Whether app lock is enabled in settings.
  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAppLockEnabled) ?? false;
  }

  /// Enables or disables app lock.
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppLockEnabled, enabled);
  }

  /// Whether personal expense lock is enabled.
  Future<bool> isExpensesLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyExpensesLockEnabled) ?? false;
  }

  /// Enables or disables personal expense lock.
  Future<void> setExpensesLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExpensesLockEnabled, enabled);
  }
}
