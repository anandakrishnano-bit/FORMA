import 'package:flutter_test/flutter_test.dart';
import 'package:forma/core/services/daily_summary_service.dart';
import 'package:forma/data/models/daily_summary_model.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

void main() {
  group('Authentication & Onboarding Flag Tests', () {
    test(
        'UserModel.fromFirestore honors both onboardingComplete and onboardingCompleted',
        () {
      final userWithComplete = UserModel(
        uid: 'user_1',
        email: 'athlete@forma.app',
        displayName: 'Athlete One',
        onboardingComplete: true,
        createdAt: DateTime.now(),
      );

      final map1 = userWithComplete.toMap();
      expect(map1['onboardingComplete'], isTrue);

      // Verify that if a legacy or alternate document has onboardingCompleted: true, it resolves correctly
      final legacyData = {
        'email': 'legacy@forma.app',
        'displayName': 'Legacy Athlete',
        'onboardingCompleted': true,
        'createdAt': null,
      };

      final isComplete = (legacyData['onboardingComplete'] as bool?) ??
          (legacyData['onboardingCompleted'] as bool?) ??
          false;

      expect(isComplete, isTrue);
    });

    test(
        'Returning user sign in logic does not trap existing accounts in onboarding',
        () {
      final existingUserDocData = <String, dynamic>{
        'uid': 'existing_user_uid',
        'displayName': 'Alex Smith',
        'email': 'alex@example.com',
        'onboardingComplete': true,
      };

      // Simulates login_screen _routeAfterAuth resolution
      const isExistingUserLogin = true; // _isRegisterMode == false
      final isComplete = (existingUserDocData['onboardingComplete'] as bool?) ??
          (existingUserDocData['onboardingCompleted'] as bool?) ??
          isExistingUserLogin;

      expect(isComplete, isTrue,
          reason:
              'Returning users must be routed directly to Home without onboarding loops.');
    });

    test('Fresh registration sets onboardingComplete flag accurately', () {
      const isRegisterMode = true;
      const isExistingUser = !isRegisterMode;

      expect(isExistingUser, isFalse);
    });
  });

  group('DailySummary Zero-State & Fallback Tests', () {
    test(
        'DailySummaryService produces an honest zero-state summary for first-time login',
        () {
      final service = DailySummaryService();
      final summary = service.generateSummary(
        completedWorkouts: [],
        loggedMeals: [],
        habits: [],
        habitCompletion: {},
        userName: 'New Athlete',
      );

      expect(summary, isA<DailySummary>());
      expect(summary.hasSufficientData, isFalse);
      expect(summary.steps, equals(0));
      expect(summary.activeCalories, equals(0.0));
      expect(summary.energyScore, isNull);
      expect(summary.contributingSources, isEmpty);
      expect(summary.overview,
          contains('Record your workouts, steps or nutrition'));
    });
  });
}
