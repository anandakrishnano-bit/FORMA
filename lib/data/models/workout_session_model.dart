import 'package:cloud_firestore/cloud_firestore.dart';

/// A single completed set within a workout session.
class CompletedSet {
  final int setNumber;
  final int reps;
  final double weight;
  final bool isPersonalRecord;

  const CompletedSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.isPersonalRecord = false,
  });

  factory CompletedSet.fromJson(Map<String, dynamic> json) {
    return CompletedSet(
      setNumber: json['setNumber'] as int,
      reps: json['reps'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      isPersonalRecord: json['isPersonalRecord'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'isPersonalRecord': isPersonalRecord,
    };
  }

  CompletedSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    bool? isPersonalRecord,
  }) {
    return CompletedSet(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isPersonalRecord: isPersonalRecord ?? this.isPersonalRecord,
    );
  }

  @override
  String toString() =>
      'CompletedSet(set: $setNumber, reps: $reps, weight: $weight, '
      'pr: $isPersonalRecord)';
}

/// A completed exercise within a workout session.
class CompletedExercise {
  final String exerciseId;
  final String exerciseName;
  final List<CompletedSet> sets;
  final Duration restTaken;

  const CompletedExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.sets = const [],
    this.restTaken = Duration.zero,
  });

  factory CompletedExercise.fromJson(Map<String, dynamic> json) {
    return CompletedExercise(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => CompletedSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      restTaken: Duration(seconds: json['restTakenSeconds'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((s) => s.toJson()).toList(),
      'restTakenSeconds': restTaken.inSeconds,
    };
  }

  CompletedExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    List<CompletedSet>? sets,
    Duration? restTaken,
  }) {
    return CompletedExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      restTaken: restTaken ?? this.restTaken,
    );
  }

  /// Total volume (weight × reps) for this exercise across all sets.
  double get totalVolume =>
      sets.fold(0.0, (sum, s) => sum + (s.weight * s.reps));

  @override
  String toString() =>
      'CompletedExercise(exerciseId: $exerciseId, name: $exerciseName, '
      'sets: ${sets.length})';
}

/// FORMA workout session model.
///
/// Records a completed workout with all performed exercises, sets, and
/// aggregate metrics.
class WorkoutSessionModel {
  final String id;
  final String userId;
  final String workoutId;
  final String workoutName;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final List<CompletedExercise> exercises;
  final double totalVolume;
  final List<String> personalRecords;
  final String notes;

  const WorkoutSessionModel({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.workoutName,
    required this.startTime,
    this.endTime,
    this.duration = Duration.zero,
    this.exercises = const [],
    this.totalVolume = 0.0,
    this.personalRecords = const [],
    this.notes = '',
  });

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      workoutId: json['workoutId'] as String,
      workoutName: json['workoutName'] as String,
      startTime: _parseDateTime(json['startTime']),
      endTime: json['endTime'] != null ? _parseDateTime(json['endTime']) : null,
      duration: Duration(seconds: json['durationSeconds'] as int? ?? 0),
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map(
                  (e) => CompletedExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
      personalRecords:
          List<String>.from(json['personalRecords'] as List? ?? []),
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationSeconds': duration.inSeconds,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'totalVolume': totalVolume,
      'personalRecords': personalRecords,
      'notes': notes,
    };
  }

  WorkoutSessionModel copyWith({
    String? id,
    String? userId,
    String? workoutId,
    String? workoutName,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    List<CompletedExercise>? exercises,
    double? totalVolume,
    List<String>? personalRecords,
    String? notes,
  }) {
    return WorkoutSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      exercises: exercises ?? this.exercises,
      totalVolume: totalVolume ?? this.totalVolume,
      personalRecords: personalRecords ?? this.personalRecords,
      notes: notes ?? this.notes,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkoutSessionModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WorkoutSessionModel(id: $id, workout: $workoutName, '
      'duration: $duration)';
}
