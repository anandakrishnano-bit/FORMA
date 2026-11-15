import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/data/models/habit.dart';

/// Repository managing habit definitions and genuine date-keyed completions.
///
/// Ensures ZERO fake data: all streaks, completion rates, and historical logs
/// are strictly derived from real user checkoffs.
class HabitRepository {
  final List<Habit> _habits = [
    Habit(
      id: 'h_workout',
      userId: 'user_local',
      title: 'Daily Workout Session',
      iconCodePoint: 0xe28d, // fitness_center
      colorValue: 0xFF88A95C, // sage green
      frequency: 'Daily',
      streakCount: 0,
      createdAt: DateTime.now(),
    ),
    Habit(
      id: 'h_water',
      userId: 'user_local',
      title: 'Drink 3L Water',
      iconCodePoint: 0xe3e0, // water_drop
      colorValue: 0xFFC5D0DE, // icy blue
      frequency: 'Daily',
      streakCount: 0,
      createdAt: DateTime.now(),
    ),
    Habit(
      id: 'h_protein',
      userId: 'user_local',
      title: 'Hit Protein Target',
      iconCodePoint: 0xe532, // restaurant
      colorValue: 0xFFFFBD35, // warm golden yellow
      frequency: 'Daily',
      streakCount: 0,
      createdAt: DateTime.now(),
    ),
  ];

  /// Date-keyed completions: key is 'yyyy-MM-dd', value is {habitId: bool}
  final Map<String, Map<String, bool>> _completionsByDate = {};

  String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<List<Habit>> getHabits() async {
    return List.unmodifiable(_habits);
  }

  Map<String, bool> getStatusForDate(DateTime date) {
    final key = _dateKey(date);
    return Map<String, bool>.from(_completionsByDate[key] ?? {});
  }

  bool isHabitCompleted(String habitId, DateTime date) {
    final key = _dateKey(date);
    return _completionsByDate[key]?[habitId] ?? false;
  }

  void toggleHabit(String habitId, DateTime date) {
    final key = _dateKey(date);
    final currentMap = _completionsByDate.putIfAbsent(key, () => {});
    final currentStatus = currentMap[habitId] ?? false;
    currentMap[habitId] = !currentStatus;
  }

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
  }

  int getCompletedCountForDate(DateTime date) {
    final status = getStatusForDate(date);
    return status.values.where((v) => v == true).length;
  }

  /// Completion percentage for a given date [0..100]
  int getPercentageForDate(DateTime date) {
    if (_habits.isEmpty) return 0;
    final completed = getCompletedCountForDate(date);
    return ((completed / _habits.length) * 100).round().clamp(0, 100);
  }

  /// Calculates genuine consecutive day streak ending on today or yesterday
  int calculateCurrentStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;

    // Check if today has at least 1 completed habit
    DateTime checkDate = today;
    if (getCompletedCountForDate(checkDate) == 0) {
      // If today has 0, check yesterday
      checkDate = today.subtract(const Duration(days: 1));
      if (getCompletedCountForDate(checkDate) == 0) {
        return 0; // Streak broken
      }
    }

    // Traverse backwards counting consecutive days with at least 1 habit checked
    while (true) {
      if (getCompletedCountForDate(checkDate) > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Total completed task checks across the specified month
  int getMonthlyCompletedTasks(DateTime monthDate) {
    int count = 0;
    final prefix =
        '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
    for (final entry in _completionsByDate.entries) {
      if (entry.key.startsWith(prefix)) {
        count += entry.value.values.where((v) => v == true).length;
      }
    }
    return count;
  }

  /// 7-day completion percentages [0..100] for Mon through Sun of the week of [referenceDate]
  List<int> getWeeklyDayPercentages(DateTime referenceDate) {
    // Find Monday of the reference week (1=Mon ... 7=Sun)
    final monday =
        referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final result = <int>[];

    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      result.add(getPercentageForDate(day));
    }

    return result;
  }

  /// 4-week completion percentages [0..100] for W1, W2, W3, W4 of the month of [referenceDate]
  List<int> getMonthlyWeekPercentages(DateTime referenceDate) {
    final firstOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);
    final result = <int>[];

    for (int w = 0; w < 4; w++) {
      final weekStart = firstOfMonth.add(Duration(days: w * 7));
      int sumPercentages = 0;
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (day.month == referenceDate.month) {
          sumPercentages += getPercentageForDate(day);
        }
      }
      result.add((sumPercentages / 7).round().clamp(0, 100));
    }

    return result;
  }
}

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

/// Notifier tracking habit completion state across all dates.
/// Increments an update counter so consumers listening to any date reactively rebuild.
class HabitRecordsNotifier extends StateNotifier<int> {
  final HabitRepository _repo;

  HabitRecordsNotifier(this._repo) : super(0);

  Map<String, bool> getStatusForDate(DateTime date) {
    return _repo.getStatusForDate(date);
  }

  void toggleHabit(String habitId, DateTime date) {
    _repo.toggleHabit(habitId, date);
    state = state + 1; // trigger notification
  }
}

final habitRecordsProvider =
    StateNotifierProvider<HabitRecordsNotifier, int>((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  return HabitRecordsNotifier(repo);
});

/// Legacy compatibility provider for today's habits
final habitStatusProvider = Provider<Map<String, bool>>((ref) {
  ref.watch(habitRecordsProvider);
  return ref.watch(habitRepositoryProvider).getStatusForDate(DateTime.now());
});

final habitsListProvider = FutureProvider<List<Habit>>((ref) async {
  return ref.watch(habitRepositoryProvider).getHabits();
});
