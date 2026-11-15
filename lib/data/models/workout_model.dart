import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a workout template containing a list of exercises.
typedef WorkoutModel = Workout;
typedef ExerciseSet = WorkoutSet;

class WorkoutSet {
  final int setNumber;
  final int targetReps;
  final double weightKg;

  const WorkoutSet({
    required this.setNumber,
    required this.targetReps,
    required this.weightKg,
  });
}

class Workout {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<WorkoutExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String color;
  final String icon;
  final int estimatedMinutes;
  final List<String> targetMuscleGroups;
  final bool isTemplate;
  final String splitType;
  final String imageUrl;

  String get title => name;
  int get estimatedDurationMinutes => estimatedMinutes;

  Workout({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    this.exercises = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.color = 'primaryAccent',
    this.icon = 'dumbbell',
    int? estimatedMinutes,
    int? estimatedDurationMinutes,
    this.targetMuscleGroups = const [],
    this.isTemplate = false,
    String? splitType,
    this.imageUrl = '',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        estimatedMinutes = estimatedMinutes ?? (estimatedDurationMinutes ?? 45),
        splitType =
            splitType ?? (description.isNotEmpty ? description : 'Full Body');

  factory Workout.fromJson(Map<String, dynamic> json) => Workout.fromMap(json);

  factory Workout.fromMap(Map<String, dynamic> data) {
    return Workout(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? (data['title'] as String? ?? ''),
      description: data['description'] as String? ?? '',
      exercises: (data['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ??
                  DateTime.now())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()) ??
                  DateTime.now())
          : DateTime.now(),
      color: data['color'] as String? ?? 'primaryAccent',
      icon: data['icon'] as String? ?? 'dumbbell',
      estimatedMinutes: data['estimatedMinutes'] as int? ??
          (data['estimatedDurationMinutes'] as int? ?? 45),
      targetMuscleGroups: (data['targetMuscleGroups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isTemplate: data['isTemplate'] as bool? ?? false,
      splitType: data['splitType'] as String?,
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
      'icon': icon,
      'estimatedMinutes': estimatedMinutes,
      'targetMuscleGroups': targetMuscleGroups,
      'isTemplate': isTemplate,
      'splitType': splitType,
      'imageUrl': imageUrl,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory Workout.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Workout.fromMap({'id': doc.id, ...data});
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'color': color,
      'icon': icon,
      'estimatedMinutes': estimatedMinutes,
      'targetMuscleGroups': targetMuscleGroups,
      'isTemplate': isTemplate,
      'splitType': splitType,
    };
  }

  Workout copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<WorkoutExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    String? icon,
    int? estimatedMinutes,
    List<String>? targetMuscleGroups,
    bool? isTemplate,
    String? splitType,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      isTemplate: isTemplate ?? this.isTemplate,
      splitType: splitType ?? this.splitType,
    );
  }
}

/// An exercise within a workout template, including target sets/reps.
class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int restSeconds;
  final String notes;
  final int order;
  final List<WorkoutSet> sets;

  int get restDurationSeconds => restSeconds;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    int? targetSets,
    this.targetReps = 10,
    this.targetWeight = 0.0,
    int? restSeconds,
    int? restDurationSeconds,
    this.notes = '',
    this.order = 0,
    List<WorkoutSet>? sets,
  })  : restSeconds = restSeconds ?? (restDurationSeconds ?? 90),
        sets = sets ??
            List.generate(
              targetSets ?? 3,
              (index) => WorkoutSet(
                setNumber: index + 1,
                targetReps: targetReps,
                weightKg: targetWeight,
              ),
            ),
        targetSets = targetSets ?? (sets?.length ?? 3);

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exerciseId: map['exerciseId'] as String? ?? '',
      exerciseName: map['exerciseName'] as String? ?? '',
      targetSets: map['targetSets'] as int? ?? 3,
      targetReps: map['targetReps'] as int? ?? 10,
      targetWeight: (map['targetWeight'] as num?)?.toDouble() ?? 0.0,
      restSeconds: map['restSeconds'] as int? ??
          (map['restDurationSeconds'] as int? ?? 90),
      notes: map['notes'] as String? ?? '',
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'restSeconds': restSeconds,
      'notes': notes,
      'order': order,
    };
  }
}

/// A completed workout session recorded in workout history.
class WorkoutSession {
  final String id;
  final String userId;
  final String workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationMinutes;
  final List<ExerciseLog> exerciseLogs;
  final double totalVolumeKg;
  final int totalSets;
  final String notes;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.completedAt,
    this.durationMinutes = 0,
    this.exerciseLogs = const [],
    this.totalVolumeKg = 0.0,
    this.totalSets = 0,
    this.notes = '',
  });

  factory WorkoutSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WorkoutSession(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      workoutId: data['workoutId'] as String? ?? '',
      workoutName: data['workoutName'] as String? ?? '',
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      exerciseLogs: (data['exerciseLogs'] as List<dynamic>?)
              ?.map((e) => ExerciseLog.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalVolumeKg: (data['totalVolumeKg'] as num?)?.toDouble() ?? 0.0,
      totalSets: data['totalSets'] as int? ?? 0,
      notes: data['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': Timestamp.fromDate(completedAt),
      'durationMinutes': durationMinutes,
      'exerciseLogs': exerciseLogs.map((e) => e.toMap()).toList(),
      'totalVolumeKg': totalVolumeKg,
      'totalSets': totalSets,
      'notes': notes,
    };
  }

  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? workoutId,
    String? workoutName,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationMinutes,
    List<ExerciseLog>? exerciseLogs,
    double? totalVolumeKg,
    int? totalSets,
    String? notes,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      totalSets: totalSets ?? this.totalSets,
      notes: notes ?? this.notes,
    );
  }
}

/// Log of a single exercise performed during a session.
class ExerciseLog {
  final String exerciseId;
  final String exerciseName;
  final List<SetLog> sets;

  const ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    this.sets = const [],
  });

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      exerciseId: map['exerciseId'] as String? ?? '',
      exerciseName: map['exerciseName'] as String? ?? '',
      sets: (map['sets'] as List<dynamic>?)
              ?.map((e) => SetLog.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((e) => e.toMap()).toList(),
    };
  }
}

/// Log of a single set within an exercise.
class SetLog {
  final int setNumber;
  final double weight;
  final int reps;
  final bool isWarmup;
  final bool isDropSet;
  final bool isFailure;

  const SetLog({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.isWarmup = false,
    this.isDropSet = false,
    this.isFailure = false,
  });

  factory SetLog.fromMap(Map<String, dynamic> map) {
    return SetLog(
      setNumber: map['setNumber'] as int? ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      reps: map['reps'] as int? ?? 0,
      isWarmup: map['isWarmup'] as bool? ?? false,
      isDropSet: map['isDropSet'] as bool? ?? false,
      isFailure: map['isFailure'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'isWarmup': isWarmup,
      'isDropSet': isDropSet,
      'isFailure': isFailure,
    };
  }
}

/// Personal record for an exercise.
class PersonalRecord {
  final String exerciseId;
  final double maxWeight;
  final int maxReps;
  final double maxVolume;
  final DateTime achievedAt;

  const PersonalRecord({
    required this.exerciseId,
    required this.maxWeight,
    required this.maxReps,
    required this.maxVolume,
    required this.achievedAt,
  });

  factory PersonalRecord.fromMap(Map<String, dynamic> map) {
    return PersonalRecord(
      exerciseId: map['exerciseId'] as String? ?? '',
      maxWeight: (map['maxWeight'] as num?)?.toDouble() ?? 0.0,
      maxReps: map['maxReps'] as int? ?? 0,
      maxVolume: (map['maxVolume'] as num?)?.toDouble() ?? 0.0,
      achievedAt: map['achievedAt'] is Timestamp
          ? (map['achievedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

/// Weekly workout statistics.
class WeeklyStats {
  final int workoutsCompleted;
  final int totalMinutes;
  final double totalVolume;
  final int totalSets;
  final Map<String, int> muscleGroupDistribution;

  const WeeklyStats({
    this.workoutsCompleted = 0,
    this.totalMinutes = 0,
    this.totalVolume = 0.0,
    this.totalSets = 0,
    this.muscleGroupDistribution = const {},
  });
}
