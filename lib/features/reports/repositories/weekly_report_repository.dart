import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:forma/core/services/app_logger.dart';
import 'package:forma/core/services/gemini_client_service.dart';
import 'package:forma/core/services/secure_storage_service.dart';
import 'package:forma/data/models/daily_summary_model.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/models/workout_session_model.dart';
import 'package:forma/data/repositories/daily_summary_repository.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:forma/features/reports/models/weekly_report_model.dart';

class WeeklyReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SecureStorageService _secureStorage;

  WeeklyReportRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SecureStorageService? secureStorage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _secureStorage = secureStorage ?? SecureStorageService();

  String? get currentUserId => _auth.currentUser?.uid;

  /// Generates or fetches the weekly intelligence report for the current or previous 7-day period.
  Future<WeeklyReport> generateWeeklyReport({
    required List<WorkoutSessionModel> workouts,
    required List<DailySummary> summaries,
    required List<PersonalExpense> expenses,
    required BudgetPlannerSummary budgetSummary,
    bool forceAiRefresh = false,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 6));
    final endDate = today;

    final weekId =
        'week_${DateFormat('yyyy_MM_dd').format(startDate)}_${DateFormat('yyyy_MM_dd').format(endDate)}';
    final uid = currentUserId;

    // Check if report already exists in Firestore unless force refresh is requested
    if (uid != null && !forceAiRefresh) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeklyReports')
            .doc(weekId)
            .get();
        if (doc.exists && doc.data() != null) {
          AppLogger.info('REPORTS', 'Loaded cached weekly report $weekId');
          return WeeklyReport.fromMap(doc.data()!);
        }
      } catch (e) {
        AppLogger.warn('REPORTS', 'Could not fetch cached weekly report: $e');
      }
    }

    // 1. Filter metrics for 7-day window
    final weekWorkouts = workouts.where((w) {
      final date =
          DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
      return !date.isBefore(startDate) && !date.isAfter(endDate);
    }).toList();

    final weekExpenses = expenses.where((e) {
      final date = DateTime(e.date.year, e.date.month, e.date.day);
      return !date.isBefore(startDate) && !date.isAfter(endDate);
    }).toList();

    final weekSummaries = summaries.where((s) {
      try {
        final d = DateFormat('yyyy-MM-dd').parse(s.date);
        return !d.isBefore(startDate) && !d.isAfter(endDate);
      } catch (_) {
        return false;
      }
    }).toList();

    // 2. Training stats
    final totalWorkouts = weekWorkouts.length;
    final totalVolumeKg =
        weekWorkouts.fold(0.0, (acc, w) => acc + w.totalVolume);
    final totalActiveMinutes =
        weekWorkouts.fold(0, (acc, w) => acc + w.duration.inMinutes);

    // 3. Activity & Steps
    final totalSteps = weekSummaries.fold(0, (acc, s) => acc + s.steps);
    final avgDailySteps =
        weekSummaries.isNotEmpty ? totalSteps ~/ weekSummaries.length : 0;

    // 4. Nutrition stats
    final nutritionDays =
        weekSummaries.where((s) => s.consumedCalories > 0).toList();
    final totalCalories =
        nutritionDays.fold(0.0, (acc, s) => acc + s.consumedCalories);
    final avgDailyCalories =
        nutritionDays.isNotEmpty ? totalCalories / nutritionDays.length : 0.0;
    final avgDailyProtein = 0.0; // Derived when macro logs available

    // 5. Habits stats
    final totalHabitsCompleted = weekSummaries.fold(0, (acc, s) {
      return acc + (s.contributingSources.contains('habits') ? 1 : 0);
    });
    final habitConsistencyRate = weekSummaries.isNotEmpty
        ? (totalHabitsCompleted / (weekSummaries.length * 3) * 100)
            .clamp(0.0, 100.0)
        : 0.0;

    // 6. Expense stats
    final totalSpent = weekExpenses.fold(0.0, (acc, e) => acc + e.amount);
    final avgDailyBurn = totalSpent / 7.0;

    final Map<String, double> catTotals = {};
    for (final exp in weekExpenses) {
      catTotals[exp.category] = (catTotals[exp.category] ?? 0.0) + exp.amount;
    }
    final topExpenseCategory = catTotals.isNotEmpty
        ? (catTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key
        : 'None';

    final allowance = budgetSummary.suggestedDailyAllowance;
    int daysWithinBudget = 0;
    for (int i = 0; i < 7; i++) {
      final day = startDate.add(Duration(days: i));
      final daySpend = weekExpenses
          .where((e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day)
          .fold(0.0, (acc, e) => acc + e.amount);
      if (allowance > 0 && daySpend <= allowance) {
        daysWithinBudget++;
      }
    }

    // 7. Grounded Highlights
    final highlights = <String>[];
    if (totalWorkouts > 0) {
      highlights.add(
          'Completed $totalWorkouts workout session(s) moving a total volume of ${totalVolumeKg.toInt()} kg.');
    } else {
      highlights.add('No structured workouts logged this week.');
    }

    if (totalSteps > 0) {
      highlights.add(
          'Logged a total of $totalSteps verified steps (avg $avgDailySteps/day).');
    }

    if (totalSpent > 0) {
      highlights.add(
          'Managed expenses with ₹${totalSpent.toStringAsFixed(0)} total spending (₹${avgDailyBurn.toStringAsFixed(0)}/day burn).');
      if (allowance > 0) {
        highlights.add(
            'Stayed under your daily allowance on $daysWithinBudget of 7 days.');
      }
    }

    // 8. Coach Synthesis (Gemini or Deterministic)
    String coachSynthesis;
    bool isAi = false;

    final geminiKey = await _secureStorage.getUserGeminiKey();
    if (geminiKey != null && geminiKey.isNotEmpty) {
      try {
        final prompt = '''
You are FORMA's elite athletic intelligence coach. Synthesize this athlete's genuine 7-day performance report into an inspiring, concise, grounded recap:

Date Range: ${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM yyyy').format(endDate)}
Workouts Completed: $totalWorkouts sessions
Total Volume Lifted: ${totalVolumeKg.toInt()} kg
Active Time: $totalActiveMinutes minutes
Steps: $totalSteps (daily avg: $avgDailySteps)
Nutrition Logged: ${nutritionDays.length} days (avg ${avgDailyCalories.toInt()} kcal/day)
Habit Consistency: ${habitConsistencyRate.toInt()}%
Finances: ₹${totalSpent.toStringAsFixed(0)} spent (avg ₹${avgDailyBurn.toStringAsFixed(0)}/day burn, top category: $topExpenseCategory)
Budget Adherence: $daysWithinBudget/7 days under target

Provide 2 short paragraphs:
1. Objective evaluation of physical and lifestyle consistency.
2. Two highly specific, actionable recommendations for the upcoming week.
Keep tone mature, athletic, and encouraging. Never invent facts not listed above.
''';

        coachSynthesis = await GeminiClientService.generateContent(
          apiKey: geminiKey,
          prompt: prompt,
        );
        isAi = true;
      } catch (e) {
        AppLogger.warn(
            'REPORTS', 'Gemini synthesis failed, using grounded fallback: $e');
        coachSynthesis = _buildDeterministicSynthesis(
          totalWorkouts: totalWorkouts,
          totalVolumeKg: totalVolumeKg,
          avgDailySteps: avgDailySteps,
          daysWithinBudget: daysWithinBudget,
          totalSpent: totalSpent,
        );
      }
    } else {
      coachSynthesis = _buildDeterministicSynthesis(
        totalWorkouts: totalWorkouts,
        totalVolumeKg: totalVolumeKg,
        avgDailySteps: avgDailySteps,
        daysWithinBudget: daysWithinBudget,
        totalSpent: totalSpent,
      );
    }

    final report = WeeklyReport(
      id: weekId,
      startDate: startDate,
      endDate: endDate,
      totalWorkouts: totalWorkouts,
      totalVolumeKg: totalVolumeKg,
      totalSteps: totalSteps,
      avgDailySteps: avgDailySteps,
      totalActiveMinutes: totalActiveMinutes,
      avgDailyCalories: avgDailyCalories,
      avgDailyProtein: avgDailyProtein,
      nutritionDaysLogged: nutritionDays.length,
      totalHabitsCompleted: totalHabitsCompleted,
      habitConsistencyRate: habitConsistencyRate,
      topHabits: [],
      totalSpent: totalSpent,
      avgDailyBurn: avgDailyBurn,
      topExpenseCategory: topExpenseCategory,
      daysWithinBudget: daysWithinBudget,
      highlights: highlights,
      coachSynthesis: coachSynthesis,
      isAiGenerated: isAi,
      generatedAt: DateTime.now(),
    );

    // Save to Firestore
    if (uid != null) {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('weeklyReports')
            .doc(weekId)
            .set(report.toMap(), SetOptions(merge: true));
        AppLogger.success(
            'REPORTS', 'Saved weekly report $weekId to Firestore');
      } catch (e) {
        AppLogger.warn('REPORTS', 'Failed to save weekly report: $e');
      }
    }

    return report;
  }

  String _buildDeterministicSynthesis({
    required int totalWorkouts,
    required double totalVolumeKg,
    required int avgDailySteps,
    required int daysWithinBudget,
    required double totalSpent,
  }) {
    final buffer = StringBuffer();
    if (totalWorkouts > 0) {
      buffer.write(
          'Great discipline across your training blocks this week. With $totalWorkouts completed sessions and ${totalVolumeKg.toInt()} kg of volume, your strength stimulus was solid. ');
    } else {
      buffer.write(
          'This week focused primarily on recovery and baseline movement. ');
    }

    if (avgDailySteps > 6000) {
      buffer.write(
          'Your cardiovascular baseline remained healthy with an average of $avgDailySteps steps per day.\n\n');
    } else {
      buffer.write('Keep aiming to build daily movement outside the gym.\n\n');
    }

    buffer.write(
        'For next week: prioritize progressive overload on primary compound movements and ensure your post-workout hydration and recovery habits remain locked in.');

    return buffer.toString();
  }
}

final weeklyReportRepositoryProvider = Provider<WeeklyReportRepository>((ref) {
  return WeeklyReportRepository();
});

final currentWeeklyReportProvider = FutureProvider<WeeklyReport>((ref) async {
  final repo = ref.watch(weeklyReportRepositoryProvider);
  final workouts = await ref.watch(workoutHistoryProvider.future);
  final summaries = ref.watch(recentDailySummariesProvider).valueOrNull ?? [];
  final expenses = ref.watch(personalExpensesStreamProvider).valueOrNull ?? [];
  final budgetSummary = ref.watch(budgetPlannerSummaryProvider);

  return repo.generateWeeklyReport(
    workouts: workouts,
    summaries: summaries,
    expenses: expenses,
    budgetSummary: budgetSummary,
  );
});
