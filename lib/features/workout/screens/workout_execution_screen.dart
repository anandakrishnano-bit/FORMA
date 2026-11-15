import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/rest_timer.dart';
import 'package:forma/core/components/workout_set_editor.dart';
import 'package:forma/core/services/live_workout_notification_service.dart';
import 'package:forma/core/services/local_workout_recovery_service.dart';
import 'package:forma/core/services/notification_service.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/workout_model.dart';
import 'package:forma/data/models/workout_session_model.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:go_router/go_router.dart';

class WorkoutExecutionScreen extends ConsumerStatefulWidget {
  final WorkoutModel workout;

  const WorkoutExecutionScreen({super.key, required this.workout});

  @override
  ConsumerState<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState
    extends ConsumerState<WorkoutExecutionScreen> {
  int _currentExerciseIndex = 0;
  late List<List<bool>> _completedSets;
  late List<List<double>> _setWeights;
  late List<List<int>> _setReps;
  int _secondsElapsed = 0;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _completedSets = widget.workout.exercises
        .map((e) => List.generate(e.sets.length, (_) => false))
        .toList();
    _setWeights = widget.workout.exercises
        .map((e) => e.sets.map((s) => s.weightKg).toList())
        .toList();
    _setReps = widget.workout.exercises
        .map((e) => e.sets.map((s) => s.targetReps).toList())
        .toList();
    _restoreOrPersistSnapshot();
    _showOngoingNotification();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    LiveWorkoutNotificationService().stopWorkoutLiveUpdate();
    super.dispose();
  }

  void _startInlineRest(int seconds) {
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = seconds);
    _showOngoingNotification(restSeconds: seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_restSecondsRemaining > 1) {
        setState(() => _restSecondsRemaining--);
        if (_restSecondsRemaining % 10 == 0) {
          _showOngoingNotification(restSeconds: _restSecondsRemaining);
        }
      } else {
        timer.cancel();
        setState(() => _restSecondsRemaining = 0);
        _showOngoingNotification();
        HapticFeedback.heavyImpact();
      }
    });
  }

  Future<void> _restoreOrPersistSnapshot() async {
    final existing =
        await LocalWorkoutRecoveryService().checkUnfinishedWorkout();
    if (existing != null &&
        (existing['workout'] as WorkoutModel).id == widget.workout.id) {
      if (mounted) {
        setState(() {
          _currentExerciseIndex = (existing['currentExerciseIndex'] as int)
              .clamp(0, widget.workout.exercises.length - 1);
          _completedSets = existing['completedSets'] as List<List<bool>>;
          _setWeights = existing['setWeights'] as List<List<double>>;
          _setReps = existing['setReps'] as List<List<int>>;
          _secondsElapsed = existing['elapsedSeconds'] as int;
        });
      }
    } else {
      _persistSnapshot();
    }
  }

  void _persistSnapshot() {
    LocalWorkoutRecoveryService().saveActiveWorkoutSnapshot(
      workout: widget.workout,
      currentExerciseIndex: _currentExerciseIndex,
      completedSets: _completedSets,
      setWeights: _setWeights,
      setReps: _setReps,
      elapsedSeconds: _secondsElapsed,
    );
  }

  void _showOngoingNotification({int? restSeconds}) {
    final currentEx = widget.workout.exercises[_currentExerciseIndex];
    NotificationService().showLiveWorkoutNotification(
      workoutName: widget.workout.name,
      currentExercise: currentEx.exerciseName,
      setNumber: 1,
      totalSets: currentEx.sets.length,
      restSecondsRemaining: restSeconds,
    );
    final totalEx = widget.workout.exercises.length;
    final progressFraction =
        totalEx > 0 ? (_currentExerciseIndex / totalEx) : 0.0;
    LiveWorkoutNotificationService().updateWorkoutLiveUpdate(
      title: widget.workout.name,
      exerciseName: currentEx.exerciseName,
      progressFraction: progressFraction,
      elapsedSeconds: _secondsElapsed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];
    final totalExercises = widget.workout.exercises.length;

    return Scaffold(
      backgroundColor:
          FormaColors.charcoal, // Charcoal background during workout execution
      appBar: AppBar(
        backgroundColor: FormaColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () {
            _showExitConfirm(context);
          },
        ),
        title: Column(
          children: [
            Text(
              widget.workout.name,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            Text(
              'Exercise ${_currentExerciseIndex + 1} of $totalExercises',
              style: const TextStyle(
                  fontSize: 12, color: FormaColors.concreteGrey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined,
                color: FormaColors.primaryAccent),
            onPressed: () => _showRestTimer(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated Exercise switcher with gliding slide & fade
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: animation, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentExerciseIndex),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise Title Banner
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: FormaColors.primaryAccent
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.fitness_center_rounded,
                                    color: FormaColors.primaryAccent, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentExercise.exerciseName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rest: ${currentExercise.restDurationSeconds}s between sets',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: FormaColors.concreteGrey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'SETS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: FormaColors.concreteGrey,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Set Editors
                        Expanded(
                          child: ListView.builder(
                            itemCount: currentExercise.sets.length,
                            itemBuilder: (context, idx) {
                              return WorkoutSetEditor(
                                setNumber: idx + 1,
                                weight: _setWeights[_currentExerciseIndex][idx],
                                reps: _setReps[_currentExerciseIndex][idx],
                                isCompleted:
                                    _completedSets[_currentExerciseIndex][idx],
                                onWeightChanged: (w) {
                                  setState(() {
                                    _setWeights[_currentExerciseIndex][idx] = w;
                                  });
                                  _persistSnapshot();
                                },
                                onRepsChanged: (r) {
                                  setState(() {
                                    _setReps[_currentExerciseIndex][idx] = r;
                                  });
                                  _persistSnapshot();
                                },
                                onCompletedChanged: (c) {
                                  setState(() {
                                    _completedSets[_currentExerciseIndex][idx] =
                                        c;
                                  });
                                  _persistSnapshot();
                                  if (c) {
                                    HapticFeedback.mediumImpact();
                                    _startInlineRest(
                                        currentExercise.restDurationSeconds > 0
                                            ? currentExercise
                                                .restDurationSeconds
                                            : 60);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Inline Non-Blocking Rest Timer Banner
              if (_restSecondsRemaining > 0) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: FormaColors.primaryAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            FormaColors.primaryAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded,
                          color: FormaColors.primaryAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Rest: ${_restSecondsRemaining}s remaining',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _restSecondsRemaining += 30);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('+30s',
                            style: TextStyle(
                                color: FormaColors.primaryAccent,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _restTimer?.cancel();
                          setState(() => _restSecondsRemaining = 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Skip',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Bottom Actions
              Row(
                children: [
                  if (_currentExerciseIndex > 0)
                    Expanded(
                      child: FormaButton(
                        label: 'Previous',
                        variant: FormaButtonVariant.secondary,
                        onPressed: () {
                          setState(() {
                            _currentExerciseIndex--;
                          });
                        },
                      ),
                    ),
                  if (_currentExerciseIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FormaButton(
                      label: _currentExerciseIndex < totalExercises - 1
                          ? 'Next Exercise'
                          : 'Finish Workout',
                      onPressed: () {
                        if (_currentExerciseIndex < totalExercises - 1) {
                          setState(() {
                            _currentExerciseIndex++;
                          });
                        } else {
                          _finishWorkout(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestTimer(BuildContext context, {int seconds = 60}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RestTimerModal(initialSeconds: seconds),
    );
  }

  void _showExitConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Workout?'),
        content: const Text('Your ongoing workout progress will be discarded.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Stay')),
          TextButton(
            onPressed: () {
              LocalWorkoutRecoveryService().clearActiveWorkoutSnapshot();
              NotificationService().cancelLiveWorkoutNotification();
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('Quit',
                style: TextStyle(color: FormaColors.coralPink)),
          ),
        ],
      ),
    );
  }

  void _finishWorkout(BuildContext context) async {
    // Calculate actual volume and completed sets
    double totalVolume = 0.0;
    final completedExercises = <CompletedExercise>[];

    for (int i = 0; i < widget.workout.exercises.length; i++) {
      final ex = widget.workout.exercises[i];
      final sets = <CompletedSet>[];
      for (int s = 0; s < ex.sets.length; s++) {
        final isDone = _completedSets[i][s];
        if (isDone) {
          final reps = _setReps[i][s];
          final weight = _setWeights[i][s];
          totalVolume += (reps * weight);
          sets.add(CompletedSet(
            setNumber: s + 1,
            reps: reps,
            weight: weight,
          ));
        }
      }
      if (sets.isNotEmpty) {
        completedExercises.add(CompletedExercise(
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          sets: sets,
        ));
      }
    }

    final durationMin = (_secondsElapsed / 60).round().clamp(1, 300);
    final session = WorkoutSessionModel(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user',
      workoutId: widget.workout.id,
      workoutName: widget.workout.name,
      startTime: DateTime.now().subtract(Duration(seconds: _secondsElapsed)),
      endTime: DateTime.now(),
      duration: Duration(minutes: durationMin),
      totalVolume: totalVolume,
      exercises: completedExercises,
      notes: 'Completed in live mode',
    );

    await ref.read(workoutRepositoryProvider).saveSession(session);
    LocalWorkoutRecoveryService().clearActiveWorkoutSnapshot();
    NotificationService().cancelLiveWorkoutNotification();
    LiveWorkoutNotificationService().stopWorkoutLiveUpdate();
    HapticFeedback.heavyImpact();

    if (!context.mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'WorkoutSummary',
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        return Dialog(
          backgroundColor: FormaColors.charcoal,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 48,
                    color: FormaColors.goldenYellow,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Workout Complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.workout.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: FormaColors.primaryAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryMetric('$durationMin', 'MINS'),
                      _buildSummaryMetric('${totalVolume.toInt()}', 'KG VOL'),
                      _buildSummaryMetric(
                        '${completedExercises.fold<int>(0, (a, e) => a + e.sets.length)}',
                        'SETS',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FormaButton(
                  label: 'Save & Return to Workouts',
                  icon: Icons.check_circle_rounded,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: FormaColors.concreteGrey,
          ),
        ),
      ],
    );
  }
}
