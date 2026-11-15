import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/forma_text_field.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/exercise_model.dart';
import 'package:forma/data/models/workout_model.dart';
import 'package:forma/data/models/workout_session_model.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:forma/features/workout/widgets/exercise_discovery_modal.dart';
import 'package:go_router/go_router.dart';

class _LoggedSetData {
  int setNumber;
  int reps;
  double weightKg;
  String setType; // 'Working', 'Warm-up', 'Drop set'

  _LoggedSetData({
    required this.setNumber,
    this.reps = 10,
    this.weightKg = 0.0,
    this.setType = 'Working',
  });
}

class _LoggedExerciseData {
  final ExerciseModel exercise;
  final List<_LoggedSetData> sets;
  String notes = '';

  _LoggedExerciseData({
    required this.exercise,
    required this.sets,
  });
}

class ManualWorkoutLogScreen extends ConsumerStatefulWidget {
  final WorkoutModel? initialWorkout;
  final ExerciseModel? initialExercise;

  const ManualWorkoutLogScreen({
    super.key,
    this.initialWorkout,
    this.initialExercise,
  });

  @override
  ConsumerState<ManualWorkoutLogScreen> createState() =>
      _ManualWorkoutLogScreenState();
}

class _ManualWorkoutLogScreenState
    extends ConsumerState<ManualWorkoutLogScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  int _durationMinutes = 45;
  final List<_LoggedExerciseData> _exercises = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    final defaultTitle = widget.initialWorkout?.name ??
        (widget.initialExercise != null
            ? '${widget.initialExercise!.name} Log'
            : 'Completed Workout');
    _titleController = TextEditingController(text: defaultTitle);
    _notesController = TextEditingController();

    if (widget.initialExercise != null) {
      _exercises.add(
        _LoggedExerciseData(
          exercise: widget.initialExercise!,
          sets: [
            _LoggedSetData(setNumber: 1, reps: 10, weightKg: 20.0),
            _LoggedSetData(setNumber: 2, reps: 10, weightKg: 25.0),
            _LoggedSetData(setNumber: 3, reps: 8, weightKg: 30.0),
          ],
        ),
      );
    }

    if (widget.initialWorkout != null) {
      _durationMinutes = widget.initialWorkout!.estimatedMinutes;
      for (final we in widget.initialWorkout!.exercises) {
        final sets = List.generate(
          we.targetSets,
          (i) => _LoggedSetData(
            setNumber: i + 1,
            reps: we.targetReps,
            weightKg: we.targetWeight,
          ),
        );
        _exercises.add(
          _LoggedExerciseData(
            exercise: ExerciseModel(
              id: we.exerciseId,
              name: we.exerciseName,
              primaryMuscle: 'Full Body',
              equipment: 'Gym',
              category: 'Strength',
            ),
            sets: sets,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addExercise(ExerciseModel exercise) {
    HapticFeedback.lightImpact();
    setState(() {
      _exercises.add(
        _LoggedExerciseData(
          exercise: exercise,
          sets: [
            _LoggedSetData(setNumber: 1, reps: 10, weightKg: 20.0),
            _LoggedSetData(setNumber: 2, reps: 10, weightKg: 20.0),
            _LoggedSetData(setNumber: 3, reps: 8, weightKg: 22.5),
          ],
        ),
      );
    });
  }

  void _addSet(int exerciseIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      final currentSets = _exercises[exerciseIndex].sets;
      final lastSet = currentSets.isNotEmpty ? currentSets.last : null;
      currentSets.add(
        _LoggedSetData(
          setNumber: currentSets.length + 1,
          reps: lastSet?.reps ?? 10,
          weightKg: lastSet?.weightKg ?? 20.0,
          setType: lastSet?.setType ?? 'Working',
        ),
      );
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      _exercises[exerciseIndex].sets.removeAt(setIndex);
      for (int i = 0; i < _exercises[exerciseIndex].sets.length; i++) {
        _exercises[exerciseIndex].sets[i].setNumber = i + 1;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveWorkout() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout title.')),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    // Calculate factual totals
    int totalSets = 0;
    double totalVolume = 0.0;
    final List<CompletedExercise> completedExercises = [];

    for (final ex in _exercises) {
      final setLogs = <CompletedSet>[];
      for (final s in ex.sets) {
        totalSets++;
        totalVolume += (s.weightKg * s.reps);
        setLogs.add(
          CompletedSet(
            setNumber: s.setNumber,
            reps: s.reps,
            weight: s.weightKg,
          ),
        );
      }
      completedExercises.add(
        CompletedExercise(
          exerciseId: ex.exercise.id,
          exerciseName: ex.exercise.name,
          sets: setLogs,
        ),
      );
    }

    final session = WorkoutSessionModel(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_1',
      workoutId: widget.initialWorkout?.id ?? 'manual_session',
      workoutName: _titleController.text.trim(),
      startTime: _selectedDate.subtract(Duration(minutes: _durationMinutes)),
      endTime: _selectedDate,
      duration: Duration(minutes: _durationMinutes),
      totalVolume: totalVolume,
      exercises: completedExercises,
      notes: _notesController.text.trim(),
    );

    await ref.read(workoutRepositoryProvider).saveSession(session);

    if (mounted) {
      setState(() => _isSaving = false);
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Logged "${session.workoutName}" ($totalSets sets, ${totalVolume.toInt()} kg volume).'),
          backgroundColor: FormaColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('Log Workout',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveWorkout,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: FormaColors.primaryAccent,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Title input
            FormaTextField(
              controller: _titleController,
              label: 'Workout Name',
              hint: 'e.g. Chest & Triceps, Leg Day',
            ),
            const SizedBox(height: 16),

            // Date & Duration Picker Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? FormaColors.darkCardBackground
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: FormaColors.primaryAccent),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? FormaColors.darkPrimaryText
                                      : FormaColors.lightPrimaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? FormaColors.darkCardBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 18, color: FormaColors.goldenYellow),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? FormaColors.darkSecondaryText
                                    : FormaColors.lightSecondaryText,
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final durationList = (<int>{
                                  15,
                                  20,
                                  25,
                                  30,
                                  35,
                                  40,
                                  45,
                                  50,
                                  55,
                                  60,
                                  75,
                                  90,
                                  120,
                                  _durationMinutes
                                }.toList()
                                  ..sort());
                                return DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value:
                                        durationList.contains(_durationMinutes)
                                            ? _durationMinutes
                                            : durationList.first,
                                    isDense: true,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? FormaColors.darkPrimaryText
                                          : FormaColors.lightPrimaryText,
                                    ),
                                    dropdownColor: isDark
                                        ? FormaColors.charcoal
                                        : Colors.white,
                                    items: durationList.map((m) {
                                      return DropdownMenuItem<int>(
                                        value: m,
                                        child: Text('$m mins'),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null)
                                        setState(() => _durationMinutes = val);
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Exercise List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exercises & Sets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final ex = await showModalBottomSheet<ExerciseModel>(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const ExerciseDiscoveryModal(),
                    );
                    if (ex != null && mounted) {
                      _addExercise(ex);
                    }
                  },
                  icon: const Icon(Icons.add_rounded,
                      size: 18, color: FormaColors.primaryAccent),
                  label: const Text(
                    'Add Exercise',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: FormaColors.primaryAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_exercises.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.fitness_center_rounded,
                        size: 40, color: FormaColors.concreteGrey),
                    const SizedBox(height: 12),
                    const Text(
                      'No exercises added yet',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Add Exercise" to search the verified exercise library.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_exercises.length, (exIndex) {
                final exData = _exercises[exIndex];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark ? FormaColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exData.exercise.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15),
                                ),
                                Text(
                                  '${exData.exercise.primaryMuscle} • ${exData.exercise.equipment}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? FormaColors.darkSecondaryText
                                        : FormaColors.lightSecondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: FormaColors.coralPink),
                            onPressed: () {
                              setState(() => _exercises.removeAt(exIndex));
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Set Table Header
                      Row(
                        children: [
                          const SizedBox(
                              width: 32,
                              child: Text('SET',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Center(
                              child: Text(
                                'WEIGHT (KG)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Center(
                              child: Text(
                                'REPS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 36),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Set Rows
                      ...List.generate(exData.sets.length, (setIndex) {
                        final s = exData.sets[setIndex];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${s.setNumber}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: '${s.weightKg}',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 8),
                                    filled: true,
                                    fillColor: isDark
                                        ? FormaColors.charcoal
                                        : FormaColors.lightSecondaryBackground,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                  ),
                                  onChanged: (v) {
                                    final val = double.tryParse(v);
                                    if (val != null) s.weightKg = val;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: '${s.reps}',
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 8),
                                    filled: true,
                                    fillColor: isDark
                                        ? FormaColors.charcoal
                                        : FormaColors.lightSecondaryBackground,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                  ),
                                  onChanged: (v) {
                                    final val = int.tryParse(v);
                                    if (val != null) s.reps = val;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () => _removeSet(exIndex, setIndex),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _addSet(exIndex),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('+ Add Set',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 12),
            FormaTextField(
              controller: _notesController,
              label: 'Workout Notes (Optional)',
              hint:
                  'e.g. Felt strong on bench press, increased incline on squats',
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            FormaButton(
              label: 'Save Workout Record',
              isLoading: _isSaving,
              onPressed: _saveWorkout,
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
