import 'package:flutter_test/flutter_test.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/models/nutrition_model.dart';
import 'package:forma/data/models/muscle_tracker_model.dart';
import 'package:forma/data/repositories/muscle_tracker_repository.dart';

void main() {
  group('Expense Minor-Unit Arithmetic & Split Tests', () {
    test('Participant share minor unit conversion preserves exact cents', () {
      const share = ParticipantShare(
        userId: 'u1',
        displayName: 'Alice',
        assignedAmount: 33.33,
      );
      expect(share.assignedInMinorUnits, 3333);
    });

    test('3-way equal split of ₹900 allocates exactly ₹300 to each', () {
      const totalAmount = 900.0;
      final totalCents = (totalAmount * 100).round(); // 90000
      final count = 3;
      final baseShareCents = totalCents ~/ count; // 30000
      final remainderCents = totalCents % count; // 0

      expect(baseShareCents / 100, 300.0);
      expect(remainderCents, 0);
    });

    test(
        '3-way equal split of ₹100 allocates 33.34 to first and 33.33 to others',
        () {
      const totalAmount = 100.0;
      final totalCents = (totalAmount * 100).round(); // 10000
      final count = 3;
      final baseShareCents = totalCents ~/ count; // 3333
      final remainderCents = totalCents % count; // 1

      final shares = <double>[];
      for (int i = 0; i < count; i++) {
        final shareCents = baseShareCents + (i < remainderCents ? 1 : 0);
        shares.add(shareCents / 100);
      }

      expect(shares[0], 33.34);
      expect(shares[1], 33.33);
      expect(shares[2], 33.33);
      expect((shares[0] + shares[1] + shares[2]), closeTo(100.0, 0.001));
    });
  });

  group('Food Portion Size Calculation Tests', () {
    test('Nutrient amount per 100g calculates exact values for custom weight',
        () {
      // e.g. Cooked Rice: 130 kcal per 100g, 2.7g protein, 28g carbs, 0.3g fat
      const basePer100g = Food(
        id: 'rice_test',
        name: 'Cooked Basmati Rice',
        category: 'Grains',
        calories: 130,
        protein: 2.7,
        carbs: 28.0,
        fat: 0.3,
        servingUnit: 'g',
        servingWeight: 100,
      );

      // Medium portion = 150g
      final nutrients150g = basePer100g.calculateNutrientsForGrams(150);

      expect(nutrients150g.calories, 195.0); // 150 / 100 * 130 = 195
      expect(
          nutrients150g.protein, closeTo(4.05, 0.01)); // 150 / 100 * 2.7 = 4.05
      expect(nutrients150g.carbs, 42.0); // 150 / 100 * 28 = 42
      expect(nutrients150g.fat, closeTo(0.45, 0.01)); // 150 / 100 * 0.3 = 0.45
    });

    test('Structured portions on food contains Small, Medium, Large tiers', () {
      const rice = Food(
        id: 'rice_1',
        name: 'Basmati Rice (Cooked)',
        category: 'Grains',
        calories: 130,
        protein: 2.7,
        carbs: 28.0,
        fat: 0.3,
      );

      final portions = rice.structuredPortions;
      expect(portions.length, 3);
      expect(portions[0].tier, PortionTier.small);
      expect(portions[0].gramEquivalent, 100);
      expect(portions[1].tier, PortionTier.medium);
      expect(portions[1].gramEquivalent, 150);
      expect(portions[2].tier, PortionTier.large);
      expect(portions[2].gramEquivalent, 250);
    });
  });

  group('Muscle Tracker & Remaining Muscles Tests', () {
    test('Canonical major muscle group lookup matches variations', () {
      expect(MajorMuscleGroup.fromName('Chest')?.name, 'Chest');
      expect(MajorMuscleGroup.fromName('pectoral')?.name, 'Chest');
      expect(MajorMuscleGroup.fromName('lats')?.name, 'Back');
      expect(MajorMuscleGroup.fromName('quads')?.name, 'Quadriceps');
      expect(MajorMuscleGroup.fromName('delts')?.name, 'Shoulders');
    });

    test('computeWeeklyMuscleStatus correctly identifies remaining muscles',
        () {
      final weekStart = DateTime(2026, 11, 16); // Monday
      final plan = WeeklyMusclePlan(
        id: 'test_plan',
        userId: 'u1',
        weekStartDate: weekStart,
        splitName: 'Push / Pull / Legs',
        dayPlans: WeeklyMusclePlan.createPPLTemplate(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Suppose user trained Push (Chest, Shoulders, Triceps) on Monday
      final logs = [
        MuscleTrainingLog(
          id: 'log1',
          userId: 'u1',
          workoutDate: weekStart,
          muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final status = MuscleTrackerRepository.computeWeeklyMuscleStatus(
        plan: plan,
        logs: logs,
        today: weekStart,
      );

      expect(status.trainedMuscles.contains('Chest'), isTrue);
      expect(status.trainedMuscles.contains('Shoulders'), isTrue);
      expect(status.trainedMuscles.contains('Triceps'), isTrue);
      // Tuesday Pull (Back, Biceps, Forearms) and Wednesday Legs are still remaining
      expect(status.plannedRemainingMuscles.contains('Back'), isTrue);
      expect(status.plannedRemainingMuscles.contains('Quadriceps'), isTrue);
      expect(status.daysTrainedCount, 1);
    });
  });
}
