import 'package:forma/data/models/exercise_model.dart';

/// Seed library of biomechanically verified core exercises with high-definition photography.
class ExerciseSeedData {
  static final List<ExerciseModel> exercises = [
    // Chest
    const ExerciseModel(
      id: 'ex_bench_press',
      name: 'Dumbbell Bench Press',
      imageUrl:
          'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=600&auto=format&fit=crop',
      primaryMuscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Dumbbells',
      difficulty: 'Intermediate',
      instructions:
          'Lie on the bench holding dumbbells at chest level. Press upwards until your arms are extended, then lower slowly.',
      category: 'dumbbells',
    ),
    const ExerciseModel(
      id: 'ex_barbell_bench',
      name: 'Barbell Flat Bench Press',
      imageUrl:
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600&auto=format&fit=crop',
      primaryMuscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'Lie flat on the bench. Lower the barbell with control to mid-chest. Press upward explosively.',
      category: 'barbells',
    ),
    const ExerciseModel(
      id: 'ex_cable_fly',
      name: 'Cable Chest Fly',
      imageUrl:
          'https://images.unsplash.com/photo-1534367507873-d2d7e24c797f?w=600&auto=format&fit=crop',
      primaryMuscle: 'Chest',
      secondaryMuscles: ['Shoulders'],
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      instructions:
          'Bring cables together in a hugging motion, maintaining a slight bend in your elbows.',
      category: 'cable',
    ),

    // Back
    const ExerciseModel(
      id: 'ex_lat_pulldown',
      name: 'Wide Grip Lat Pulldown',
      imageUrl:
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600&auto=format&fit=crop',
      primaryMuscle: 'Back',
      secondaryMuscles: ['Biceps'],
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      instructions:
          'Grip wide. Pull bar down towards upper chest while driving elbows downwards. Slowly return to top.',
      category: 'cable',
    ),
    const ExerciseModel(
      id: 'ex_deadlift',
      name: 'Conventional Barbell Deadlift',
      imageUrl:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&auto=format&fit=crop',
      primaryMuscle: 'Back',
      secondaryMuscles: ['Hamstrings', 'Glutes', 'Core'],
      equipment: 'Barbell',
      difficulty: 'Advanced',
      instructions:
          'Stand mid-foot under bar. Hinge down, grip firmly, brace core, and drive through floor to full standing lockout.',
      category: 'barbells',
    ),

    // Shoulders
    const ExerciseModel(
      id: 'ex_overhead_press',
      name: 'Overhead Barbell Press',
      imageUrl:
          'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=600&auto=format&fit=crop',
      primaryMuscle: 'Shoulders',
      secondaryMuscles: ['Triceps', 'Core'],
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'Stand tall with core braced. Press barbell straight overhead until arms lockout.',
      category: 'barbells',
    ),
    const ExerciseModel(
      id: 'ex_lateral_raise',
      name: 'Dumbbell Lateral Raise',
      imageUrl:
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&auto=format&fit=crop',
      primaryMuscle: 'Shoulders',
      secondaryMuscles: ['Forearms'],
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      instructions:
          'Raise dumbbells to shoulder height leading with elbows. Control the descent.',
      category: 'dumbbells',
    ),

    // Legs
    const ExerciseModel(
      id: 'ex_barbell_squat',
      name: 'Barbell Back Squat',
      imageUrl:
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&auto=format&fit=crop',
      primaryMuscle: 'Quadriceps',
      secondaryMuscles: ['Glutes', 'Hamstrings', 'Core'],
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'Descend by breaking at hips and knees simultaneously. Reach parallel or below, then drive up through mid-foot.',
      category: 'barbells',
    ),
    const ExerciseModel(
      id: 'ex_hip_thrust',
      name: 'Barbell Hip Thrust',
      imageUrl:
          'https://images.unsplash.com/photo-1530822847156-5df684ec5ee1?w=600&auto=format&fit=crop',
      primaryMuscle: 'Glutes',
      secondaryMuscles: ['Hamstrings'],
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'Shoulders against bench, barbell over hips. Drive through heels to extend hips fully, holding squeeze at top.',
      category: 'barbells',
    ),

    // Arms
    const ExerciseModel(
      id: 'ex_db_bicep_curl',
      name: 'Standing Dumbbell Curl',
      imageUrl:
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600&auto=format&fit=crop',
      primaryMuscle: 'Biceps',
      secondaryMuscles: ['Forearms'],
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      instructions:
          'Curl dumbbells upward while supinating wrists. Squeeze biceps at the top and lower slowly.',
      category: 'dumbbells',
    ),
  ];
}
