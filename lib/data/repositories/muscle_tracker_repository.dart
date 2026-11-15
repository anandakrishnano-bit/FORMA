import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/data/models/exercise_model.dart';
import 'package:forma/data/models/muscle_tracker_model.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

final muscleTrackerRepositoryProvider =
    Provider<MuscleTrackerRepository>((ref) {
  return MuscleTrackerRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

/// Returns start of the week (Monday) for a given date
DateTime getStartOfWeek(DateTime date) {
  final clean = DateTime(date.year, date.month, date.day);
  return clean.subtract(Duration(days: clean.weekday - 1));
}

/// Stream of muscle training logs for the active week
final currentWeekMuscleLogsProvider =
    StreamProvider<List<MuscleTrainingLog>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);
  final startOfWeek = getStartOfWeek(DateTime.now());
  return ref
      .watch(muscleTrackerRepositoryProvider)
      .streamWeekTrainingLogs(user.uid, startOfWeek);
});

/// Stream of weekly muscle plan
final currentWeeklyPlanProvider = StreamProvider<WeeklyMusclePlan?>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value(null);
  final startOfWeek = getStartOfWeek(DateTime.now());
  return ref
      .watch(muscleTrackerRepositoryProvider)
      .streamWeeklyPlan(user.uid, startOfWeek);
});

/// User body & activity preferences
final bodyPreferencesProvider = FutureProvider<BodyPreferences>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return const BodyPreferences();
  return ref
      .watch(muscleTrackerRepositoryProvider)
      .getBodyPreferences(user.uid);
});

class MuscleTrackerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MuscleTrackerRepository(this._firestore, this._auth);

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference _logsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('muscleTrainingLogs');

  CollectionReference _plansCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('weeklyMusclePlans');

  DocumentReference _prefsDoc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('preferences')
      .doc('body_activity');

  // ═══════════════════════════════════════════════════════════════════════════
  // TRAINING LOGS
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<MuscleTrainingLog>> streamWeekTrainingLogs(
      String uid, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _logsCol(uid)
        .where('workoutDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('workoutDate', isLessThan: Timestamp.fromDate(weekEnd))
        .orderBy('workoutDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MuscleTrainingLog.fromFirestore(doc))
            .toList());
  }

  Stream<List<MuscleTrainingLog>> streamAllTrainingLogs(String uid) {
    return _logsCol(uid)
        .orderBy('workoutDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MuscleTrainingLog.fromFirestore(doc))
            .toList());
  }

  Future<void> logMuscleTraining(MuscleTrainingLog log) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _logsCol(uid).add(log.toMap());
  }

  Future<void> updateTrainingLog(MuscleTrainingLog log) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _logsCol(uid).doc(log.id).update(log.toMap());
  }

  Future<void> deleteTrainingLog(String logId) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _logsCol(uid).doc(logId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEEKLY PLANS
  // ═══════════════════════════════════════════════════════════════════════════

  String getWeekId(DateTime weekStart) {
    return 'week_${weekStart.year}_${weekStart.month.toString().padLeft(2, '0')}_${weekStart.day.toString().padLeft(2, '0')}';
  }

  Stream<WeeklyMusclePlan?> streamWeeklyPlan(String uid, DateTime weekStart) {
    final weekId = getWeekId(weekStart);
    return _plansCol(uid).doc(weekId).snapshots().map((doc) {
      if (!doc.exists) {
        // Return default Push / Pull / Legs plan if no custom plan exists
        return WeeklyMusclePlan(
          id: weekId,
          userId: uid,
          weekStartDate: weekStart,
          splitName: 'Push / Pull / Legs',
          dayPlans: WeeklyMusclePlan.createPPLTemplate(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      return WeeklyMusclePlan.fromFirestore(doc);
    });
  }

  Future<void> saveWeeklyPlan(WeeklyMusclePlan plan) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    final weekId = getWeekId(plan.weekStartDate);
    await _plansCol(uid).doc(weekId).set(plan.toMap(), SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY PREFERENCES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<BodyPreferences> getBodyPreferences(String uid) async {
    try {
      final doc = await _prefsDoc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return const BodyPreferences();
      }
      return BodyPreferences.fromMap(doc.data() as Map<String, dynamic>);
    } catch (_) {
      return const BodyPreferences();
    }
  }

  Future<void> saveBodyPreferences(BodyPreferences prefs) async {
    final uid = currentUid;
    if (uid == null) return;
    await _prefsDoc(uid).set(prefs.toMap(), SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTOMATIC MUSCLE GROUP DETECTION FROM EXERCISES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Derives canonical muscle groups from actual exercises in a workout
  static List<String> deriveMusclesFromExercises(
      List<ExerciseModel> exercises) {
    final groups = <String>{};

    for (final exercise in exercises) {
      final canonical = MajorMuscleGroup.fromName(exercise.primaryMuscle);
      if (canonical != null) {
        groups.add(canonical.name);
      }
      for (final secondary in exercise.secondaryMuscles) {
        final secCanonical = MajorMuscleGroup.fromName(secondary);
        if (secCanonical != null) {
          groups.add(secCanonical.name);
        }
      }
    }

    return groups.toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REMAINING MUSCLE GROUPS COMPUTATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculates which muscle groups have been trained this week,
  /// which are still planned for remaining days, and which remain unworked.
  static ({
    Set<String> trainedMuscles,
    Set<String> plannedRemainingMuscles,
    Set<String> allWeeklyPlanned,
    int daysTrainedCount,
    int restDaysCount,
  }) computeWeeklyMuscleStatus({
    required WeeklyMusclePlan plan,
    required List<MuscleTrainingLog> logs,
    required DateTime today,
  }) {
    final trainedMuscles = <String>{};
    for (final log in logs) {
      trainedMuscles.addAll(log.muscleGroups);
    }

    final allPlanned = plan.allWeeklyPlannedMuscles;

    // Remaining days of week: from today (or tomorrow) to Sunday
    final currentDayOfWeek = today.weekday; // 1 = Monday .. 7 = Sunday
    final plannedRemaining = <String>{};
    int restDays = 0;

    for (int day = currentDayOfWeek; day <= 7; day++) {
      final dayPlan = plan.dayPlans[day];
      if (dayPlan != null) {
        if (dayPlan.isRestDay) {
          restDays++;
        } else {
          for (final m in dayPlan.plannedMuscles) {
            if (!trainedMuscles.contains(m)) {
              plannedRemaining.add(m);
            }
          }
        }
      }
    }

    // Number of distinct days on which workouts were logged
    final trainedDates = logs
        .map((l) =>
            '${l.workoutDate.year}_${l.workoutDate.month}_${l.workoutDate.day}')
        .toSet();

    return (
      trainedMuscles: trainedMuscles,
      plannedRemainingMuscles: plannedRemaining,
      allWeeklyPlanned: allPlanned,
      daysTrainedCount: trainedDates.length,
      restDaysCount: restDays,
    );
  }
}
