import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/services/daily_summary_service.dart';
import 'package:forma/core/services/health_connect_service.dart';
import 'package:forma/data/models/daily_summary_model.dart';
import 'package:forma/data/models/workout_model.dart';
import 'package:forma/data/models/workout_session_model.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:forma/data/repositories/nutrition_repository.dart';
import 'package:forma/data/repositories/habit_repository.dart';
import 'package:forma/data/models/habit.dart';
import 'package:forma/data/models/nutrition_model.dart';

final dailySummaryServiceProvider = Provider<DailySummaryService>((ref) {
  return DailySummaryService();
});

final dailySummaryRepositoryProvider = Provider<DailySummaryRepository>((ref) {
  return DailySummaryRepository();
});

class DailySummaryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DailySummaryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _summariesCollection {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('dailySummaries');
  }

  /// Saves or reconciles the daily summary for the specified date string (YYYY-MM-DD).
  Future<void> saveDailySummary(DailySummary summary) async {
    final col = _summariesCollection;
    if (col == null) return;
    try {
      await col.doc(summary.date).set(summary.toMap(), SetOptions(merge: true));
    } catch (_) {
      // In offline mode Firestore cache buffers the write
    }
  }

  /// Fetches daily summary for a given date string (YYYY-MM-DD).
  Future<DailySummary?> getDailySummary(String dateStr) async {
    final col = _summariesCollection;
    if (col == null) return null;
    try {
      final doc = await col.doc(dateStr).get();
      if (doc.exists && doc.data() != null) {
        return DailySummary.fromMap(doc.data()!);
      }
    } catch (_) {}
    return null;
  }

  /// Streams recent daily summaries for history view.
  Stream<List<DailySummary>> streamRecentDailySummaries({int limit = 14}) {
    final col = _summariesCollection;
    if (col == null) return Stream.value([]);
    return col
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DailySummary.fromMap(doc.data()))
          .toList();
    });
  }
}

final todaySummaryProvider = FutureProvider<DailySummary>((ref) async {
  final summaryService = ref.watch(dailySummaryServiceProvider);
  final repo = ref.watch(dailySummaryRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;
  final now = DateTime.now();

  try {
    final history = await ref
        .watch(workoutRepositoryProvider)
        .getHistory()
        .catchError((_) => <WorkoutSessionModel>[]);
    final meals = await ref
        .watch(todayMealsProvider.future)
        .catchError((_) => <MealEntry>[]);
    final habits =
        await ref.watch(habitsListProvider.future).catchError((_) => <Habit>[]);
    final habitStatus = ref.watch(habitStatusProvider);

    // Genuine completed workouts for today only
    final todaySessions = history.where((s) {
      return s.startTime.year == now.year &&
          s.startTime.month == now.month &&
          s.startTime.day == now.day;
    }).toList();

    final List<WorkoutModel> completedWorkoutModels = todaySessions.map((s) {
      return WorkoutModel(
        id: s.id,
        userId: s.userId,
        name: s.workoutName,
        targetMuscleGroups: [],
        exercises: [],
        estimatedDurationMinutes: s.duration.inMinutes,
        createdAt: s.startTime,
      );
    }).toList();

    // Fetch verified Health Connect metrics if authorized (with fast timeout so it never blocks Home render)
    final healthMetrics = await HealthConnectService()
        .fetchDailyMetrics(now)
        .timeout(const Duration(milliseconds: 1200),
            onTimeout: () => DailyHealthMetrics(timestamp: now))
        .catchError((_) => DailyHealthMetrics(timestamp: now));

    final summary = summaryService.generateSummary(
      completedWorkouts: completedWorkoutModels,
      loggedMeals: meals,
      habits: habits,
      habitCompletion: habitStatus,
      userName: user?.displayName ?? 'Athlete',
      steps: healthMetrics.steps,
      activeCalories: healthMetrics.activeCalories,
      heartRateBpm: healthMetrics.heartRateBpm,
    );

    // Asynchronously persist / reconcile to Firestore dailySummaries
    if (user != null) {
      repo.saveDailySummary(summary).ignore();
    }

    return summary;
  } catch (_) {
    // Return honest initial summary on fresh login or offline network latency
    return summaryService.generateSummary(
      completedWorkouts: [],
      loggedMeals: [],
      habits: [],
      habitCompletion: {},
      userName: user?.displayName ?? 'Athlete',
    );
  }
});

final recentDailySummariesProvider = StreamProvider<List<DailySummary>>((ref) {
  final repo = ref.watch(dailySummaryRepositoryProvider);
  return repo.streamRecentDailySummaries(limit: 14);
});
