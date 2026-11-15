import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Major canonical muscle groups recognized in FORMA
class MajorMuscleGroup {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isFront;
  final bool isBack;
  final String description;

  const MajorMuscleGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isFront = true,
    this.isBack = true,
    required this.description,
  });

  static const List<MajorMuscleGroup> all = [
    MajorMuscleGroup(
      id: 'chest',
      name: 'Chest',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFFF7A59), // Terracotta
      isFront: true,
      isBack: false,
      description:
          'Pectoralis major and minor responsible for horizontal pressing and adduction.',
    ),
    MajorMuscleGroup(
      id: 'back',
      name: 'Back',
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFF54A0FF), // Azure
      isFront: false,
      isBack: true,
      description:
          'Latissimus dorsi, rhomboids, and trapezius for pulling and vertical posture.',
    ),
    MajorMuscleGroup(
      id: 'shoulders',
      name: 'Shoulders',
      icon: Icons.shield_rounded,
      color: Color(0xFFFFC443), // Golden Yellow
      isFront: true,
      isBack: true,
      description:
          'Anterior, lateral, and posterior deltoids for overhead stability and rotation.',
    ),
    MajorMuscleGroup(
      id: 'biceps',
      name: 'Biceps',
      icon: Icons.sports_gymnastics_rounded,
      color: Color(0xFF8B80F9), // Lavender
      isFront: true,
      isBack: false,
      description:
          'Biceps brachii providing elbow flexion and forearm supination.',
    ),
    MajorMuscleGroup(
      id: 'triceps',
      name: 'Triceps',
      icon: Icons.sports_mma_rounded,
      color: Color(0xFFD4C7F5),
      isFront: false,
      isBack: true,
      description:
          'Triceps brachii across 3 heads responsible for elbow extension.',
    ),
    MajorMuscleGroup(
      id: 'forearms',
      name: 'Forearms',
      icon: Icons.pan_tool_rounded,
      color: Color(0xFFB8B7B5),
      isFront: true,
      isBack: true,
      description:
          'Brachioradialis and wrist flexors/extensors powering grip strength.',
    ),
    MajorMuscleGroup(
      id: 'quadriceps',
      name: 'Quadriceps',
      icon: Icons.directions_run_rounded,
      color: Color(0xFF7AA868), // Sage
      isFront: true,
      isBack: false,
      description:
          'Rectus femoris and vastus muscles driving knee extension and squatting.',
    ),
    MajorMuscleGroup(
      id: 'hamstrings',
      name: 'Hamstrings',
      icon: Icons.airline_seat_legroom_extra_rounded,
      color: Color(0xFF659253),
      isFront: false,
      isBack: true,
      description:
          'Biceps femoris and semitendinosus for knee flexion and hip extension.',
    ),
    MajorMuscleGroup(
      id: 'glutes',
      name: 'Glutes',
      icon: Icons.accessibility_rounded,
      color: Color(0xFFE98557),
      isFront: false,
      isBack: true,
      description:
          'Gluteus maximus and medius powering primary pelvic drive and sprint speed.',
    ),
    MajorMuscleGroup(
      id: 'calves',
      name: 'Calves',
      icon: Icons.skateboarding_rounded,
      color: Color(0xFF88A95C),
      isFront: true,
      isBack: true,
      description:
          'Gastrocnemius and soleus driving ankle plantar flexion and jumping.',
    ),
    MajorMuscleGroup(
      id: 'abs',
      name: 'Abs',
      icon: Icons.grid_view_rounded,
      color: Color(0xFFFFAA2C),
      isFront: true,
      isBack: false,
      description:
          'Rectus abdominis powering trunk flexion and core compression.',
    ),
    MajorMuscleGroup(
      id: 'core',
      name: 'Core',
      icon: Icons.adjust_rounded,
      color: Color(0xFFFFAA2C),
      isFront: true,
      isBack: true,
      description:
          'Transverse abdominis and lower back erectors for rotational stability.',
    ),
  ];

  static MajorMuscleGroup? fromName(String name) {
    final lower = name.trim().toLowerCase();
    for (final m in all) {
      if (m.name.toLowerCase() == lower || m.id.toLowerCase() == lower) {
        return m;
      }
    }
    // Partial matching for synonyms
    if (lower.contains('chest') || lower.contains('pec')) return all[0];
    if (lower.contains('back') || lower.contains('lat')) return all[1];
    if (lower.contains('shoulder') || lower.contains('delt')) return all[2];
    if (lower.contains('bicep')) return all[3];
    if (lower.contains('tricep')) return all[4];
    if (lower.contains('forearm') || lower.contains('grip')) return all[5];
    if (lower.contains('quad') || lower.contains('thigh')) return all[6];
    if (lower.contains('hamstring')) return all[7];
    if (lower.contains('glute') || lower.contains('butt')) return all[8];
    if (lower.contains('calf') || lower.contains('calves')) return all[9];
    if (lower.contains('ab') || lower.contains('abdominal')) return all[10];
    if (lower.contains('core') || lower.contains('oblique')) return all[11];
    return null;
  }
}

/// A single logged session where muscle groups were trained
class MuscleTrainingLog {
  final String id;
  final String userId;
  final DateTime workoutDate;
  final List<String> muscleGroups;
  final String? linkedWorkoutId;
  final String? workoutTitle;
  final List<String> contributingExercises;
  final String? note;
  final String source; // 'auto_workout', 'manual_log'
  final DateTime createdAt;
  final DateTime updatedAt;

  const MuscleTrainingLog({
    required this.id,
    required this.userId,
    required this.workoutDate,
    required this.muscleGroups,
    this.linkedWorkoutId,
    this.workoutTitle,
    this.contributingExercises = const [],
    this.note,
    this.source = 'manual_log',
    required this.createdAt,
    required this.updatedAt,
  });

  factory MuscleTrainingLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MuscleTrainingLog(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      workoutDate:
          (data['workoutDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      muscleGroups:
          (data['muscleGroups'] as List<dynamic>?)?.cast<String>() ?? [],
      linkedWorkoutId: data['linkedWorkoutId'] as String?,
      workoutTitle: data['workoutTitle'] as String?,
      contributingExercises:
          (data['contributingExercises'] as List<dynamic>?)?.cast<String>() ??
              [],
      note: data['note'] as String?,
      source: data['source'] as String? ?? 'manual_log',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workoutDate': Timestamp.fromDate(workoutDate),
      'muscleGroups': muscleGroups,
      'linkedWorkoutId': linkedWorkoutId,
      'workoutTitle': workoutTitle,
      'contributingExercises': contributingExercises,
      'note': note,
      'source': source,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Day-level training plan within a week
class DayMusclePlan {
  final int dayOfWeek; // 1 = Monday .. 7 = Sunday
  final bool isRestDay;
  final List<String> plannedMuscles;
  final String? label;

  const DayMusclePlan({
    required this.dayOfWeek,
    this.isRestDay = false,
    this.plannedMuscles = const [],
    this.label,
  });

  Map<String, dynamic> toMap() => {
        'dayOfWeek': dayOfWeek,
        'isRestDay': isRestDay,
        'plannedMuscles': plannedMuscles,
        'label': label,
      };

  factory DayMusclePlan.fromMap(Map<String, dynamic> map) => DayMusclePlan(
        dayOfWeek: map['dayOfWeek'] as int? ?? 1,
        isRestDay: map['isRestDay'] as bool? ?? false,
        plannedMuscles:
            (map['plannedMuscles'] as List<dynamic>?)?.cast<String>() ?? [],
        label: map['label'] as String?,
      );

  DayMusclePlan copyWith({
    bool? isRestDay,
    List<String>? plannedMuscles,
    String? label,
  }) {
    return DayMusclePlan(
      dayOfWeek: dayOfWeek,
      isRestDay: isRestDay ?? this.isRestDay,
      plannedMuscles: plannedMuscles ?? this.plannedMuscles,
      label: label ?? this.label,
    );
  }
}

/// User's weekly muscle training split and planner
class WeeklyMusclePlan {
  final String id;
  final String userId;
  final DateTime weekStartDate;
  final String splitName;
  final Map<int, DayMusclePlan> dayPlans; // 1..7
  final DateTime createdAt;
  final DateTime updatedAt;

  const WeeklyMusclePlan({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.splitName,
    required this.dayPlans,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get all distinct planned muscles across the entire week
  Set<String> get allWeeklyPlannedMuscles {
    final set = <String>{};
    for (final day in dayPlans.values) {
      if (!day.isRestDay) {
        set.addAll(day.plannedMuscles);
      }
    }
    return set;
  }

  factory WeeklyMusclePlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawDayPlans = data['dayPlans'] as Map<String, dynamic>? ?? {};

    final parsedDays = <int, DayMusclePlan>{};
    for (int i = 1; i <= 7; i++) {
      if (rawDayPlans.containsKey('$i')) {
        parsedDays[i] =
            DayMusclePlan.fromMap(rawDayPlans['$i'] as Map<String, dynamic>);
      } else {
        parsedDays[i] = DayMusclePlan(dayOfWeek: i);
      }
    }

    return WeeklyMusclePlan(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      weekStartDate:
          (data['weekStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      splitName: data['splitName'] as String? ?? 'Push / Pull / Legs',
      dayPlans: parsedDays,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final serializedDays = <String, dynamic>{};
    for (final entry in dayPlans.entries) {
      serializedDays['${entry.key}'] = entry.value.toMap();
    }
    return {
      'userId': userId,
      'weekStartDate': Timestamp.fromDate(weekStartDate),
      'splitName': splitName,
      'dayPlans': serializedDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Built-in standard training split templates
  static Map<int, DayMusclePlan> createPPLTemplate() {
    return {
      1: const DayMusclePlan(
          dayOfWeek: 1,
          label: 'Push',
          plannedMuscles: ['Chest', 'Shoulders', 'Triceps']),
      2: const DayMusclePlan(
          dayOfWeek: 2,
          label: 'Pull',
          plannedMuscles: ['Back', 'Biceps', 'Forearms']),
      3: const DayMusclePlan(
          dayOfWeek: 3,
          label: 'Legs',
          plannedMuscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves']),
      4: const DayMusclePlan(dayOfWeek: 4, label: 'Rest Day', isRestDay: true),
      5: const DayMusclePlan(
          dayOfWeek: 5,
          label: 'Upper',
          plannedMuscles: ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps']),
      6: const DayMusclePlan(
          dayOfWeek: 6,
          label: 'Lower & Core',
          plannedMuscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Abs']),
      7: const DayMusclePlan(dayOfWeek: 7, label: 'Rest Day', isRestDay: true),
    };
  }

  static Map<int, DayMusclePlan> createUpperLowerTemplate() {
    return {
      1: const DayMusclePlan(
          dayOfWeek: 1,
          label: 'Upper Body A',
          plannedMuscles: ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps']),
      2: const DayMusclePlan(
          dayOfWeek: 2,
          label: 'Lower Body A',
          plannedMuscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves']),
      3: const DayMusclePlan(dayOfWeek: 3, label: 'Rest Day', isRestDay: true),
      4: const DayMusclePlan(
          dayOfWeek: 4,
          label: 'Upper Body B',
          plannedMuscles: ['Chest', 'Back', 'Shoulders', 'Core']),
      5: const DayMusclePlan(
          dayOfWeek: 5,
          label: 'Lower Body B',
          plannedMuscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Abs']),
      6: const DayMusclePlan(
          dayOfWeek: 6, label: 'Active Recovery', isRestDay: true),
      7: const DayMusclePlan(dayOfWeek: 7, label: 'Rest Day', isRestDay: true),
    };
  }

  static Map<int, DayMusclePlan> createFullBodyTemplate() {
    return {
      1: const DayMusclePlan(
          dayOfWeek: 1,
          label: 'Full Body 1',
          plannedMuscles: ['Chest', 'Back', 'Quadriceps', 'Core']),
      2: const DayMusclePlan(dayOfWeek: 2, label: 'Rest Day', isRestDay: true),
      3: const DayMusclePlan(
          dayOfWeek: 3,
          label: 'Full Body 2',
          plannedMuscles: [
            'Shoulders',
            'Hamstrings',
            'Glutes',
            'Biceps',
            'Triceps'
          ]),
      4: const DayMusclePlan(dayOfWeek: 4, label: 'Rest Day', isRestDay: true),
      5: const DayMusclePlan(
          dayOfWeek: 5,
          label: 'Full Body 3',
          plannedMuscles: ['Chest', 'Back', 'Quadriceps', 'Calves', 'Abs']),
      6: const DayMusclePlan(dayOfWeek: 6, label: 'Rest Day', isRestDay: true),
      7: const DayMusclePlan(dayOfWeek: 7, label: 'Rest Day', isRestDay: true),
    };
  }
}

/// Optional Body and Activity setup preferences
class BodyPreferences {
  final String units; // 'metric' (kg, cm) or 'imperial' (lbs, in)
  final String experienceLevel; // 'Beginner', 'Intermediate', 'Advanced'
  final List<String> trainingInterests;
  final List<String> priorityMuscles;
  final bool enableHealthConnect;

  const BodyPreferences({
    this.units = 'metric',
    this.experienceLevel = 'Intermediate',
    this.trainingInterests = const ['Hypertrophy', 'Strength'],
    this.priorityMuscles = const ['Chest', 'Back', 'Quadriceps'],
    this.enableHealthConnect = false,
  });

  Map<String, dynamic> toMap() => {
        'units': units,
        'experienceLevel': experienceLevel,
        'trainingInterests': trainingInterests,
        'priorityMuscles': priorityMuscles,
        'enableHealthConnect': enableHealthConnect,
      };

  factory BodyPreferences.fromMap(Map<String, dynamic> map) => BodyPreferences(
        units: map['units'] as String? ?? 'metric',
        experienceLevel: map['experienceLevel'] as String? ?? 'Intermediate',
        trainingInterests:
            (map['trainingInterests'] as List<dynamic>?)?.cast<String>() ??
                ['Hypertrophy', 'Strength'],
        priorityMuscles:
            (map['priorityMuscles'] as List<dynamic>?)?.cast<String>() ??
                ['Chest', 'Back', 'Quadriceps'],
        enableHealthConnect: map['enableHealthConnect'] as bool? ?? false,
      );
}
