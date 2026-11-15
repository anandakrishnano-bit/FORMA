import 'package:cloud_firestore/cloud_firestore.dart';

/// Muscle group categories for exercises.
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  quads,
  hamstrings,
  glutes,
  calves,
  core,
  fullBody,
  cardio;

  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.quads:
        return 'Quads';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.fullBody:
        return 'Full Body';
      case MuscleGroup.cardio:
        return 'Cardio';
    }
  }

  static MuscleGroup fromString(String value) {
    return MuscleGroup.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MuscleGroup.fullBody,
    );
  }
}

/// Equipment types for exercises.
enum Equipment {
  barbell,
  dumbbell,
  cable,
  machine,
  bodyweight,
  kettlebell,
  resistanceBand,
  smith,
  ezBar,
  trapBar,
  none;

  String get displayName {
    switch (this) {
      case Equipment.barbell:
        return 'Barbell';
      case Equipment.dumbbell:
        return 'Dumbbell';
      case Equipment.cable:
        return 'Cable';
      case Equipment.machine:
        return 'Machine';
      case Equipment.bodyweight:
        return 'Bodyweight';
      case Equipment.kettlebell:
        return 'Kettlebell';
      case Equipment.resistanceBand:
        return 'Resistance Band';
      case Equipment.smith:
        return 'Smith Machine';
      case Equipment.ezBar:
        return 'EZ Bar';
      case Equipment.trapBar:
        return 'Trap Bar';
      case Equipment.none:
        return 'None';
    }
  }

  static Equipment fromString(String value) {
    return Equipment.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Equipment.none,
    );
  }
}

/// Exercise difficulty levels.
enum ExerciseDifficulty {
  beginner,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case ExerciseDifficulty.beginner:
        return 'Beginner';
      case ExerciseDifficulty.intermediate:
        return 'Intermediate';
      case ExerciseDifficulty.advanced:
        return 'Advanced';
    }
  }

  static ExerciseDifficulty fromString(String value) {
    return ExerciseDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseDifficulty.intermediate,
    );
  }
}

/// Exercise category for grouping.
enum ExerciseCategory {
  strength,
  cardio,
  flexibility,
  mobility,
  plyometrics,
  compound,
  isolation;

  String get displayName {
    switch (this) {
      case ExerciseCategory.strength:
        return 'Strength';
      case ExerciseCategory.cardio:
        return 'Cardio';
      case ExerciseCategory.flexibility:
        return 'Flexibility';
      case ExerciseCategory.mobility:
        return 'Mobility';
      case ExerciseCategory.plyometrics:
        return 'Plyometrics';
      case ExerciseCategory.compound:
        return 'Compound';
      case ExerciseCategory.isolation:
        return 'Isolation';
    }
  }

  static ExerciseCategory fromString(String value) {
    return ExerciseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseCategory.strength,
    );
  }
}

/// Exercise model representing a single exercise in the library.
typedef ExerciseModel = Exercise;

class Exercise {
  final String id;
  final String name;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String equipment;
  final String difficulty;
  final String instructions;
  final String category;
  final String imageUrl;
  final bool isCustom;

  MuscleGroup get primaryMuscleGroup => MuscleGroup.fromString(primaryMuscle);
  Equipment get equipmentType => Equipment.fromString(equipment);
  ExerciseDifficulty get difficultyLevel =>
      ExerciseDifficulty.fromString(difficulty);
  ExerciseCategory get categoryType => ExerciseCategory.fromString(category);

  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    this.difficulty = 'Intermediate',
    this.instructions = '',
    required this.category,
    this.imageUrl = '',
    this.isCustom = false,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      Exercise.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Exercise(
      id: doc.id,
      name: data['name'] as String? ?? '',
      primaryMuscle: data['primaryMuscle'] as String? ?? '',
      secondaryMuscles: (data['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      equipment: data['equipment'] as String? ?? '',
      difficulty: data['difficulty'] as String? ?? 'Intermediate',
      instructions: data['instructions'] as String? ?? '',
      category: data['category'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      isCustom: data['isCustom'] as bool? ?? false,
    );
  }

  factory Exercise.fromMap(Map<String, dynamic> data) {
    return Exercise(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      primaryMuscle: data['primaryMuscle'] as String? ?? '',
      secondaryMuscles: (data['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      equipment: data['equipment'] as String? ?? '',
      difficulty: data['difficulty'] as String? ?? 'Intermediate',
      instructions: data['instructions'] as String? ?? '',
      category: data['category'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      isCustom: data['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'primaryMuscle': primaryMuscle,
      'secondaryMuscles': secondaryMuscles,
      'equipment': equipment,
      'difficulty': difficulty,
      'instructions': instructions,
      'category': category,
      'imageUrl': imageUrl,
      'isCustom': isCustom,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      ...toFirestore(),
    };
  }
}
