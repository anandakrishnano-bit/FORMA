import 'package:flutter_test/flutter_test.dart';
import 'package:forma/features/home/models/home_card_config.dart';
import 'package:forma/features/reports/models/weekly_report_model.dart';

void main() {
  group('Home Screen Customization Tests', () {
    test('Default home cards are ordered and visible', () {
      final defaults = HomeCardConfig.defaults;
      expect(defaults.length, 8);
      for (int i = 0; i < defaults.length; i++) {
        expect(defaults[i].order, i);
        expect(defaults[i].isVisible, true);
      }
    });

    test('HomeCardConfig copyWith and toMap serialization', () {
      final card = HomeCardConfig.defaults.first;
      final toggled = card.copyWith(isVisible: false, order: 5);

      expect(toggled.id, card.id);
      expect(toggled.isVisible, false);
      expect(toggled.order, 5);

      final map = toggled.toMap();
      expect(map['id'], card.id);
      expect(map['isVisible'], false);
      expect(map['order'], 5);
    });
  });

  group('Weekly Intelligence Report Model Tests', () {
    test('WeeklyReport calculates volume and averages accurately', () {
      final now = DateTime.now();
      final report = WeeklyReport(
        id: 'test_week',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
        totalWorkouts: 4,
        totalVolumeKg: 16500.0,
        totalSteps: 56000,
        avgDailySteps: 8000,
        totalActiveMinutes: 240,
        avgDailyCalories: 2450.0,
        avgDailyProtein: 155.0,
        nutritionDaysLogged: 6,
        totalHabitsCompleted: 18,
        habitConsistencyRate: 85.7,
        topHabits: ['Hydration', 'Stretching'],
        totalSpent: 3500.0,
        avgDailyBurn: 500.0,
        topExpenseCategory: 'Food & Drinks',
        daysWithinBudget: 6,
        highlights: ['Hit 16,500 kg volume', 'Averaged 8,000 steps/day'],
        coachSynthesis: 'Excellent training consistency across all 4 sessions.',
        isAiGenerated: true,
        generatedAt: now,
      );

      expect(report.totalWorkouts, 4);
      expect(report.totalVolumeKg, 16500.0);
      expect(report.avgDailySteps, 8000);
      expect(report.daysWithinBudget, 6);
      expect(report.isAiGenerated, true);
      expect(report.highlights.length, 2);
    });
  });
}
