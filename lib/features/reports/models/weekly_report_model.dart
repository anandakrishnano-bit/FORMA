import 'package:cloud_firestore/cloud_firestore.dart';

/// Structured Weekly Intelligence Report Model for FORMA.
///
/// ZERO FAKE DATA GUARANTEE:
/// - Aggregated strictly from real workouts, genuine meals, real habits, and actual expense ledgers.
class WeeklyReport {
  final String id;
  final DateTime startDate;
  final DateTime endDate;

  // Activity & Training
  final int totalWorkouts;
  final double totalVolumeKg;
  final int totalSteps;
  final int avgDailySteps;
  final int totalActiveMinutes;

  // Nutrition
  final double avgDailyCalories;
  final double avgDailyProtein;
  final int nutritionDaysLogged;

  // Habits
  final int totalHabitsCompleted;
  final double habitConsistencyRate;
  final List<String> topHabits;

  // Expenses
  final double totalSpent;
  final double avgDailyBurn;
  final String topExpenseCategory;
  final int daysWithinBudget;

  // Grounded Highlights & AI Analysis
  final List<String> highlights;
  final String coachSynthesis;
  final bool isAiGenerated;
  final DateTime generatedAt;

  const WeeklyReport({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalWorkouts,
    required this.totalVolumeKg,
    required this.totalSteps,
    required this.avgDailySteps,
    required this.totalActiveMinutes,
    required this.avgDailyCalories,
    required this.avgDailyProtein,
    required this.nutritionDaysLogged,
    required this.totalHabitsCompleted,
    required this.habitConsistencyRate,
    required this.topHabits,
    required this.totalSpent,
    required this.avgDailyBurn,
    required this.topExpenseCategory,
    required this.daysWithinBudget,
    required this.highlights,
    required this.coachSynthesis,
    this.isAiGenerated = false,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalWorkouts': totalWorkouts,
      'totalVolumeKg': totalVolumeKg,
      'totalSteps': totalSteps,
      'avgDailySteps': avgDailySteps,
      'totalActiveMinutes': totalActiveMinutes,
      'avgDailyCalories': avgDailyCalories,
      'avgDailyProtein': avgDailyProtein,
      'nutritionDaysLogged': nutritionDaysLogged,
      'totalHabitsCompleted': totalHabitsCompleted,
      'habitConsistencyRate': habitConsistencyRate,
      'topHabits': topHabits,
      'totalSpent': totalSpent,
      'avgDailyBurn': avgDailyBurn,
      'topExpenseCategory': topExpenseCategory,
      'daysWithinBudget': daysWithinBudget,
      'highlights': highlights,
      'coachSynthesis': coachSynthesis,
      'isAiGenerated': isAiGenerated,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }

  factory WeeklyReport.fromMap(Map<String, dynamic> map) {
    return WeeklyReport(
      id: map['id'] as String? ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalWorkouts: (map['totalWorkouts'] as num?)?.toInt() ?? 0,
      totalVolumeKg: (map['totalVolumeKg'] as num?)?.toDouble() ?? 0.0,
      totalSteps: (map['totalSteps'] as num?)?.toInt() ?? 0,
      avgDailySteps: (map['avgDailySteps'] as num?)?.toInt() ?? 0,
      totalActiveMinutes: (map['totalActiveMinutes'] as num?)?.toInt() ?? 0,
      avgDailyCalories: (map['avgDailyCalories'] as num?)?.toDouble() ?? 0.0,
      avgDailyProtein: (map['avgDailyProtein'] as num?)?.toDouble() ?? 0.0,
      nutritionDaysLogged: (map['nutritionDaysLogged'] as num?)?.toInt() ?? 0,
      totalHabitsCompleted: (map['totalHabitsCompleted'] as num?)?.toInt() ?? 0,
      habitConsistencyRate:
          (map['habitConsistencyRate'] as num?)?.toDouble() ?? 0.0,
      topHabits: (map['topHabits'] as List<dynamic>?)?.cast<String>() ?? [],
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0.0,
      avgDailyBurn: (map['avgDailyBurn'] as num?)?.toDouble() ?? 0.0,
      topExpenseCategory: map['topExpenseCategory'] as String? ?? 'General',
      daysWithinBudget: (map['daysWithinBudget'] as num?)?.toInt() ?? 0,
      highlights: (map['highlights'] as List<dynamic>?)?.cast<String>() ?? [],
      coachSynthesis: map['coachSynthesis'] as String? ?? '',
      isAiGenerated: map['isAiGenerated'] as bool? ?? false,
      generatedAt:
          (map['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
