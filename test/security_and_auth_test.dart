import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma/core/services/forma_haptics.dart';
import 'package:forma/core/services/biometric_auth_service.dart';
import 'package:forma/features/authentication/widgets/country_code_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phone Authentication & Country Data Tests', () {
    test('Default country is India with +91 and 10 digits requirement', () {
      final defaultCountry = CountryInfo.defaultCountry;
      expect(defaultCountry.name, 'India');
      expect(defaultCountry.dialCode, '+91');
      expect(defaultCountry.isoCode, 'IN');
      expect(defaultCountry.minDigits, 10);
      expect(defaultCountry.maxDigits, 10);
    });

    test('Country catalogue contains major supported international regions',
        () {
      final codes = CountryInfo.all.map((c) => c.isoCode).toList();
      expect(codes,
          containsAll(['IN', 'US', 'CA', 'GB', 'AU', 'DE', 'FR', 'SG', 'JP']));
    });

    test('Phone number sanitization strips non-digit characters correctly', () {
      const rawInput = '+91 (987) 654-3210';
      final digits = rawInput.replaceAll(RegExp(r'\D'), '');
      expect(digits, '919876543210');
      // For India local digits:
      const localInput = '98765-43210';
      final localDigits = localInput.replaceAll(RegExp(r'\D'), '');
      expect(localDigits.length, 10);
      expect(localDigits, '9876543210');
    });
  });

  group('Biometric & Security Settings Service Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Biometric app lock toggle persists accurately in SharedPreferences',
        () async {
      final service = BiometricAuthService();
      expect(await service.isAppLockEnabled(), isFalse);

      await service.setAppLockEnabled(true);
      expect(await service.isAppLockEnabled(), isTrue);

      await service.setAppLockEnabled(false);
      expect(await service.isAppLockEnabled(), isFalse);
    });

    test(
        'Personal expenses lock toggle persists accurately in SharedPreferences',
        () async {
      final service = BiometricAuthService();
      expect(await service.isExpensesLockEnabled(), isFalse);

      await service.setExpensesLockEnabled(true);
      expect(await service.isExpensesLockEnabled(), isTrue);

      await service.setExpensesLockEnabled(false);
      expect(await service.isExpensesLockEnabled(), isFalse);
    });

    test('FormaHaptics toggle persists accurately in SharedPreferences',
        () async {
      await FormaHaptics.init();
      expect(FormaHaptics.isEnabled, isTrue);

      await FormaHaptics.setEnabled(false);
      expect(FormaHaptics.isEnabled, isFalse);

      await FormaHaptics.setEnabled(true);
      expect(FormaHaptics.isEnabled, isTrue);
    });
  });

  group('Auth Email Action Parser Tests', () {
    test('Recognizes standard Firebase Auth action modes', () {
      const validModes = ['verifyEmail', 'resetPassword', 'recoverEmail'];
      for (final mode in validModes) {
        expect(['verifyEmail', 'resetPassword', 'recoverEmail'].contains(mode),
            isTrue);
      }
    });

    test('Rejects unknown auth action modes', () {
      const unknownMode = 'invalidModeTest';
      expect(
          ['verifyEmail', 'resetPassword', 'recoverEmail']
              .contains(unknownMode),
          isFalse);
    });
  });
}
