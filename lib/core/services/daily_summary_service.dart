import 'package:forma/data/models/daily_summary_model.dart';
import 'package:forma/data/models/workout_model.dart';
import 'package:forma/data/models/nutrition_model.dart';
import 'package:forma/data/models/habit.dart';

class DailySummaryService {
  DailySummaryService();

  /// Factual, grounded Energy Score calculation (1 to 100).
  ///
  /// ZERO FAKE DATA GUARANTEE:
  /// Returns null if there are no contributing verified data sources.
  int? calculateBaseEnergyScore({
    required List<WorkoutModel> workouts,
    required int steps,
    required List<MealEntry> meals,
    required int completedHabits,
    required int totalHabits,
  }) {
    // Check if there is sufficient data to legitimately evaluate daily score
    final hasWorkouts = workouts.isNotEmpty;
    final hasSteps = steps > 0;
    final hasMeals = meals.isNotEmpty;
    final hasHabits = completedHabits > 0;

    if (!hasWorkouts && !hasSteps && !hasMeals && !hasHabits) {
      return null; // Insufficient data
    }

    double score = 0.0;

    // 1. Workouts (up to 35 pts)
    if (hasWorkouts) {
      score += 25.0;
      if (workouts.length >= 2) score += 10.0;
    }

    // 2. Movement / Steps (up to 30 pts)
    if (hasSteps) {
      final stepFraction = (steps / 10000.0).clamp(0.0, 1.0);
      score += (stepFraction * 30.0);
    }

    // 3. Nutrition adherence (up to 20 pts)
    if (hasMeals) {
      score += 12.0;
      if (meals.length >= 3) score += 8.0;
    }

    // 4. Habits (up to 15 pts)
    if (totalHabits > 0 && hasHabits) {
      final habitFraction = (completedHabits / totalHabits).clamp(0.0, 1.0);
      score += (habitFraction * 15.0);
    }

    return score.round().clamp(1, 100);
  }

  DailySummary generateSummary({
    required List<WorkoutModel> completedWorkouts,
    required List<MealEntry> loggedMeals,
    required List<Habit> habits,
    required Map<String, bool> habitCompletion,
    required String userName,
    int steps = 0,
    double activeCalories = 0.0,
    double? heartRateBpm,
    int waterMl = 0,
  }) {
    final workoutNames = completedWorkouts.map((w) => w.name).join(', ');
    final totalCalories =
        loggedMeals.fold<double>(0, (sum, m) => sum + m.totalCalories);
    final totalProtein =
        loggedMeals.fold<double>(0, (sum, m) => sum + m.totalProtein);

    final completedHabitsCount =
        habits.where((h) => habitCompletion[h.id] == true).length;
    final totalHabitsCount = habits.length;

    final contributingSources = <String>[];
    final missingSources = <String>[];

    if (completedWorkouts.isNotEmpty) {
      contributingSources
          .add('${completedWorkouts.length} workout(s) ($workoutNames)');
    } else {
      missingSources.add('No workout recorded');
    }

    if (steps > 0) {
      contributingSources.add('$steps steps');
    } else {
      missingSources.add('Step tracking inactive');
    }

    if (loggedMeals.isNotEmpty) {
      contributingSources
          .add('${loggedMeals.length} meals (${totalCalories.toInt()} kcal)');
    } else {
      missingSources.add('Meals not logged');
    }

    if (completedHabitsCount > 0) {
      contributingSources.add('$completedHabitsCount habits completed');
    } else if (totalHabitsCount > 0) {
      missingSources.add('Habits not checked');
    }

    final calculatedScore = calculateBaseEnergyScore(
      workouts: completedWorkouts,
      steps: steps,
      meals: loggedMeals,
      completedHabits: completedHabitsCount,
      totalHabits: totalHabitsCount,
    );

    final hasSufficient = calculatedScore != null;
    final rationale = hasSufficient
        ? 'Calculated from verified daily records: ${contributingSources.join(", ")}.'
        : 'Not enough activity data to calculate your score yet.';

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    return DailySummary(
      date: todayStr,
      hasSufficientData: hasSufficient,
      energyScore: calculatedScore,
      scoringRationale: rationale,
      steps: steps,
      activeCalories: activeCalories,
      consumedCalories: totalCalories,
      heartRateBpm: heartRateBpm,
      waterMl: waterMl,
      contributingSources: contributingSources,
      missingSources: missingSources,
      overview: hasSufficient
          ? (completedWorkouts.isNotEmpty
              ? 'You stayed consistent today and checked off your scheduled workout.'
              : 'Logged progress across your daily nutrition and consistency.')
          : 'Record your workouts, steps or nutrition to generate an explainable score.',
      workoutSummary: completedWorkouts.isNotEmpty
          ? 'Completed $workoutNames.'
          : 'No workout recorded for today.',
      nutritionSummary: loggedMeals.isNotEmpty
          ? 'Recorded ${totalCalories.toInt()} kcal with ${totalProtein.toInt()}g protein across ${loggedMeals.length} meals.'
          : 'Meals not logged yet for today.',
      habitsSummary: totalHabitsCount > 0
          ? 'Checked off $completedHabitsCount of $totalHabitsCount habits today.'
          : 'No active habits scheduled.',
      highlight: completedHabitsCount > 0
          ? 'Maintained your streak on daily habits!'
          : (completedWorkouts.isNotEmpty
              ? 'Session logged successfully.'
              : 'Begin logging to build momentum.'),
      suggestionForTomorrow: completedWorkouts.isNotEmpty
          ? 'Continue with your planned split or enjoy active recovery.'
          : 'Tomorrow is an opportunity to log your training session.',
      syncStatus: 'synced',
      lastSyncedAt: DateTime.now(),
      timezone: DateTime.now().timeZoneName,
    );
  }
}
