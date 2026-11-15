/// A single day's activity data for the weekly chart.
class DayActivity {
  final String dayLabel; // "Mon", "Tue", etc.
  final int workoutCount;
  final double completionRate; // 0.0 – 1.0

  const DayActivity({
    required this.dayLabel,
    required this.workoutCount,
    required this.completionRate,
  });
}

/// Weekly activity overview used in the home dashboard chart.
class WeeklyActivity {
  final List<DayActivity> days;
  final int totalWorkouts;
  final double habitCompletionPercent;
  final double nutritionConsistency;

  const WeeklyActivity({
    required this.days,
    required this.totalWorkouts,
    required this.habitCompletionPercent,
    required this.nutritionConsistency,
  });
}
