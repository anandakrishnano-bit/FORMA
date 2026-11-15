/// Data model for a today's workout summary shown on the home dashboard.
class WorkoutSummary {
  final String id;
  final String name;
  final List<String> muscleGroups;
  final int exerciseCount;
  final int estimatedMinutes;
  final bool isCompleted;

  const WorkoutSummary({
    required this.id,
    required this.name,
    required this.muscleGroups,
    required this.exerciseCount,
    required this.estimatedMinutes,
    this.isCompleted = false,
  });

  WorkoutSummary copyWith({
    String? id,
    String? name,
    List<String>? muscleGroups,
    int? exerciseCount,
    int? estimatedMinutes,
    bool? isCompleted,
  }) {
    return WorkoutSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      exerciseCount: exerciseCount ?? this.exerciseCount,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) {
    return WorkoutSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroups: List<String>.from(json['muscleGroups'] as List),
      exerciseCount: json['exerciseCount'] as int,
      estimatedMinutes: json['estimatedMinutes'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroups': muscleGroups,
      'exerciseCount': exerciseCount,
      'estimatedMinutes': estimatedMinutes,
      'isCompleted': isCompleted,
    };
  }
}
