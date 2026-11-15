import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma/core/services/app_logger.dart';
import 'package:forma/data/repositories/habit_repository.dart';

/// Genuine, persistent Hydration tracker keyed by date.
/// Zero fake values: tracks exactly what the user logs.
class HydrationRepository {
  final Ref _ref;
  final SharedPreferences? _prefs;

  HydrationRepository(this._ref, this._prefs);

  static const int dailyTargetMl = 3000;

  String _dateKey(DateTime date) {
    return 'hydration_ml_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';
  }

  int getTodayWaterMl() {
    final key = _dateKey(DateTime.now());
    return _prefs?.getInt(key) ?? 0;
  }

  Future<int> addWater(int amountMl) async {
    final current = getTodayWaterMl();
    final newAmount = (current + amountMl).clamp(0, 10000);
    final key = _dateKey(DateTime.now());
    await _prefs?.setInt(key, newAmount);
    AppLogger.info(
        'HYDRATION', 'Logged +$amountMl ml water. Total today: $newAmount ml');

    // If target reached, auto-mark habit
    if (newAmount >= dailyTargetMl) {
      final habitRepo = _ref.read(habitRepositoryProvider);
      final currentStatus = habitRepo.getStatusForDate(DateTime.now());
      if (currentStatus['h_water'] != true) {
        habitRepo.toggleHabit('h_water', DateTime.now());
        _ref.invalidate(habitRecordsProvider);
      }
    }

    return newAmount;
  }

  Future<int> setWater(int amountMl) async {
    final newAmount = amountMl.clamp(0, 10000);
    final key = _dateKey(DateTime.now());
    await _prefs?.setInt(key, newAmount);
    AppLogger.info('HYDRATION', 'Set water to: $newAmount ml');
    return newAmount;
  }

  Future<void> resetWater() async {
    final key = _dateKey(DateTime.now());
    await _prefs?.setInt(key, 0);
    AppLogger.info('HYDRATION', 'Reset water to 0 ml');
  }
}

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

class DailyHydrationNotifier extends StateNotifier<int> {
  final HydrationRepository _repo;

  DailyHydrationNotifier(this._repo) : super(_repo.getTodayWaterMl());

  Future<void> addWater(int amountMl) async {
    final newTotal = await _repo.addWater(amountMl);
    state = newTotal;
  }

  Future<void> setWater(int amountMl) async {
    final newTotal = await _repo.setWater(amountMl);
    state = newTotal;
  }

  Future<void> resetWater() async {
    await _repo.resetWater();
    state = 0;
  }
}

final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return HydrationRepository(ref, prefs);
});

final dailyHydrationProvider =
    StateNotifierProvider<DailyHydrationNotifier, int>((ref) {
  final repo = ref.watch(hydrationRepositoryProvider);
  return DailyHydrationNotifier(repo);
});
