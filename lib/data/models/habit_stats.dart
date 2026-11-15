/// Aggregated statistics for a single habit.
class HabitStats {
  final String habitId;
  final int currentStreak;
  final int bestStreak;
  final double completionRate; // 0.0 – 1.0
  final int totalCompletions;
  final double averagePerWeek;

  const HabitStats({
    required this.habitId,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
    required this.totalCompletions,
    required this.averagePerWeek,
  });
}
