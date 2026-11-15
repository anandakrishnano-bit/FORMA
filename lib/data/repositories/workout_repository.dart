import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/data/models/workout_model.dart';
import 'package:forma/data/models/workout_session_model.dart';
import 'package:forma/data/models/exercise_model.dart';
import 'package:forma/data/sources/exercise_seed_data.dart';

class WorkoutRepository {
  final List<WorkoutModel> _customWorkouts = [
    WorkoutModel(
      id: 'w_push_day',
      userId: 'user_1',
      name: 'Push Day Hypertrophy',
      imageUrl:
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=800&q=80',
      targetMuscleGroups: ['Chest', 'Shoulders', 'Triceps'],
      estimatedDurationMinutes: 55,
      isTemplate: true,
      splitType: 'Push / Pull / Legs',
      exercises: [
        WorkoutExercise(
          exerciseId: 'ex_bench_press',
          exerciseName: 'Barbell Bench Press',
          order: 1,
          restDurationSeconds: 90,
          sets: [
            ExerciseSet(setNumber: 1, targetReps: 10, weightKg: 60.0),
            ExerciseSet(setNumber: 2, targetReps: 8, weightKg: 70.0),
            ExerciseSet(setNumber: 3, targetReps: 6, weightKg: 75.0),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'ex_overhead_press',
          exerciseName: 'Overhead Barbell Press',
          order: 2,
          restDurationSeconds: 60,
          sets: [
            ExerciseSet(setNumber: 1, targetReps: 10, weightKg: 40.0),
            ExerciseSet(setNumber: 2, targetReps: 10, weightKg: 40.0),
            ExerciseSet(setNumber: 3, targetReps: 8, weightKg: 45.0),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'ex_tricep_pushdown',
          exerciseName: 'Tricep Rope Pushdown',
          order: 3,
          restDurationSeconds: 45,
          sets: [
            ExerciseSet(setNumber: 1, targetReps: 12, weightKg: 20.0),
            ExerciseSet(setNumber: 2, targetReps: 12, weightKg: 22.5),
            ExerciseSet(setNumber: 3, targetReps: 10, weightKg: 25.0),
          ],
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    WorkoutModel(
      id: 'w_pull_day',
      userId: 'user_1',
      name: 'Pull Day Strength',
      imageUrl:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=800&q=80',
      targetMuscleGroups: ['Back', 'Biceps'],
      estimatedDurationMinutes: 50,
      isTemplate: true,
      splitType: 'Push / Pull / Legs',
      exercises: [
        WorkoutExercise(
          exerciseId: 'ex_lat_pulldown',
          exerciseName: 'Lat Pulldown',
          order: 1,
          restDurationSeconds: 60,
          sets: [
            ExerciseSet(setNumber: 1, targetReps: 12, weightKg: 50.0),
            ExerciseSet(setNumber: 2, targetReps: 10, weightKg: 55.0),
            ExerciseSet(setNumber: 3, targetReps: 8, weightKg: 60.0),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'ex_db_bicep_curl',
          exerciseName: 'Dumbbell Bicep Curl',
          order: 2,
          restDurationSeconds: 45,
          sets: [
            ExerciseSet(setNumber: 1, targetReps: 12, weightKg: 14.0),
            ExerciseSet(setNumber: 2, targetReps: 10, weightKg: 16.0),
          ],
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ];

  final List<WorkoutSessionModel> _history = [];

  Future<List<WorkoutModel>> getWorkoutTemplates() async {
    return _customWorkouts;
  }

  Future<List<ExerciseModel>> getExercises() async {
    return ExerciseSeedData.exercises;
  }

  Future<void> saveWorkout(WorkoutModel workout) async {
    _customWorkouts.add(workout);
  }

  Future<void> saveSession(WorkoutSessionModel session) async {
    _history.insert(0, session);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workout_logs')
            .doc(session.id)
            .set({
          'id': session.id,
          'workoutId': session.workoutId,
          'workoutName': session.workoutName,
          'completedAt': Timestamp.fromDate(session.endTime ?? DateTime.now()),
          'durationMinutes': session.duration.inMinutes,
          'totalVolumeKg': session.totalVolume,
          'exercisesCount': session.exercises.length,
          'notes': session.notes,
        });
      } catch (_) {
        // Fallback to local memory if offline
      }
    }
  }

  Future<List<WorkoutSessionModel>> getHistory() async {
    if (_history.isNotEmpty) return _history;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workout_logs')
            .orderBy('completedAt', descending: true)
            .get();

        for (final doc in snap.docs) {
          final d = doc.data();
          final exists = _history.any((s) => s.id == doc.id);
          if (!exists) {
            _history.add(
              WorkoutSessionModel(
                id: doc.id,
                userId: user.uid,
                workoutId: d['workoutId'] as String? ?? 'workout',
                workoutName: d['workoutName'] as String? ?? 'Workout',
                startTime: (d['completedAt'] as Timestamp?)?.toDate().subtract(
                          Duration(
                              minutes:
                                  (d['durationMinutes'] as num?)?.toInt() ??
                                      45),
                        ) ??
                    DateTime.now(),
                endTime: (d['completedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                duration: Duration(
                    minutes: (d['durationMinutes'] as num?)?.toInt() ?? 45),
                totalVolume: (d['totalVolumeKg'] as num?)?.toDouble() ?? 0.0,
                exercises: [],
                notes: d['notes'] as String? ?? '',
              ),
            );
          }
        }
      } catch (_) {
        // Return existing cache
      }
    }
    return _history;
  }
}

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

final workoutTemplatesProvider =
    FutureProvider<List<WorkoutModel>>((ref) async {
  return ref.watch(workoutRepositoryProvider).getWorkoutTemplates();
});

final workoutHistoryProvider =
    FutureProvider<List<WorkoutSessionModel>>((ref) async {
  return ref.watch(workoutRepositoryProvider).getHistory();
});

final exerciseListProvider = FutureProvider<List<ExerciseModel>>((ref) async {
  return ref.watch(workoutRepositoryProvider).getExercises();
});
