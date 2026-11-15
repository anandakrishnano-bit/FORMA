import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:forma/data/models/workout_model.dart';

/// Local SQLite Storage Engine for Offline Workout Sessions & Recovery.
///
/// CRITICAL REQUIREMENT:
/// When a user starts a workout, its progress (current exercise, sets, reps, weight)
/// is autosaved to SQLite on every modification. If the phone shuts down, app is killed,
/// or loses battery, the active session is immediately restorable on next launch.
class LocalWorkoutRecoveryService {
  static final LocalWorkoutRecoveryService _instance =
      LocalWorkoutRecoveryService._internal();
  factory LocalWorkoutRecoveryService() => _instance;
  LocalWorkoutRecoveryService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'forma_local_recovery.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE active_workout_recovery (
            id TEXT PRIMARY KEY,
            workout_json TEXT NOT NULL,
            current_exercise_index INTEGER NOT NULL,
            completed_sets_json TEXT NOT NULL,
            weights_json TEXT NOT NULL,
            reps_json TEXT NOT NULL,
            elapsed_seconds INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE offline_sync_queue (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ACTIVE WORKOUT CRASH / KILL RECOVERY
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> saveActiveWorkoutSnapshot({
    required WorkoutModel workout,
    required int currentExerciseIndex,
    required List<List<bool>> completedSets,
    required List<List<double>> setWeights,
    required List<List<int>> setReps,
    required int elapsedSeconds,
  }) async {
    final db = await database;
    await db.insert(
      'active_workout_recovery',
      {
        'id': 'active_session',
        'workout_json': json.encode(workout.toJson()),
        'current_exercise_index': currentExerciseIndex,
        'completed_sets_json': json.encode(completedSets),
        'weights_json': json.encode(setWeights),
        'reps_json': json.encode(setReps),
        'elapsed_seconds': elapsedSeconds,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> checkUnfinishedWorkout() async {
    final db = await database;
    final results = await db.query(
      'active_workout_recovery',
      where: 'id = ?',
      whereArgs: ['active_session'],
    );

    if (results.isNotEmpty) {
      final row = results.first;
      return {
        'workout':
            WorkoutModel.fromJson(json.decode(row['workout_json'] as String)),
        'currentExerciseIndex': row['current_exercise_index'] as int,
        'completedSets':
            (json.decode(row['completed_sets_json'] as String) as List)
                .map((e) => List<bool>.from(e))
                .toList(),
        'setWeights': (json.decode(row['weights_json'] as String) as List)
            .map((e) => (e as List).map((n) => (n as num).toDouble()).toList())
            .toList(),
        'setReps': (json.decode(row['reps_json'] as String) as List)
            .map((e) => List<int>.from(e))
            .toList(),
        'elapsedSeconds': row['elapsed_seconds'] as int,
      };
    }
    return null;
  }

  Future<void> clearActiveWorkoutSnapshot() async {
    final db = await database;
    await db.delete('active_workout_recovery',
        where: 'id = ?', whereArgs: ['active_session']);
  }
}
