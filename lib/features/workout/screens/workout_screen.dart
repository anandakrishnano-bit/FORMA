import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/components/exercise_card.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/muscle_group_selector.dart';
import 'package:forma/core/components/search_field.dart';
import 'package:forma/core/components/section_header.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/repositories/discovery_repository.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:forma/features/workout/screens/workout_execution_screen.dart';
import 'package:go_router/go_router.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  List<String> _selectedMuscles = [];
  final TextEditingController _searchController = TextEditingController();
  String _exerciseSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workoutsAsync = ref.watch(workoutTemplatesProvider);
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('Workout',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _showHistorySheet(context),
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Workout History',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: FormaColors.primaryAccent,
          onRefresh: () async {
            ref.invalidate(workoutTemplatesProvider);
            ref.invalidate(exerciseListProvider);
            ref.invalidate(workoutHistoryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Bar
                FormaSearchField(
                  controller: _searchController,
                  hintText: 'Search routines or exercises...',
                  onChanged: (query) {
                    setState(() => _exerciseSearchQuery = query.trim());
                    ref.read(exerciseDiscoveryProvider.notifier).search(query);
                  },
                ),
                const SizedBox(height: 20),

                // 2. Muscle Group Selector
                MuscleGroupSelector(
                  selectedGroups: _selectedMuscles,
                  onChanged: (muscles) {
                    setState(() {
                      _selectedMuscles = muscles;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Quick Actions Bar: Start Blank / Log Post-Gym Workout
                Row(
                  children: [
                    Expanded(
                      child: FormaButton(
                        label: 'Log Workout',
                        icon: Icons.edit_note_rounded,
                        variant: FormaButtonVariant.secondary,
                        onPressed: () => context.push('/workout/manual-log'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormaButton(
                        label: 'New Routine',
                        icon: Icons.add_rounded,
                        onPressed: () => context.push('/workout/manual-log'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 3. My Routines & Splits Section
                const FormaSectionHeader(title: 'Routines & Splits'),
                const SizedBox(height: 14),

                workoutsAsync.when(
                  data: (workouts) {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: workouts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, index) {
                        final workout = workouts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OpenContainer(
                            closedElevation: 0,
                            openElevation: 0,
                            closedColor: Colors.transparent,
                            openColor: isDark
                                ? FormaColors.darkBackground
                                : FormaColors.lightBackground,
                            transitionDuration:
                                const Duration(milliseconds: 440),
                            transitionType: ContainerTransitionType.fadeThrough,
                            closedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            closedBuilder: (context, openContainer) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? FormaColors.darkCardBackground
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.25 : 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (workout.imageUrl.isNotEmpty)
                                      SizedBox(
                                        height: 130,
                                        width: double.infinity,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: workout.imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                color: FormaColors.primaryAccent
                                                    .withValues(alpha: 0.15),
                                                child: const Center(
                                                    child: Icon(
                                                        Icons
                                                            .fitness_center_rounded,
                                                        color: FormaColors
                                                            .charcoal,
                                                        size: 32)),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                color: FormaColors.primaryAccent
                                                    .withValues(alpha: 0.15),
                                                child: const Center(
                                                    child: Icon(
                                                        Icons
                                                            .fitness_center_rounded,
                                                        color: FormaColors
                                                            .charcoal,
                                                        size: 32)),
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.black
                                                        .withValues(alpha: 0.1),
                                                    Colors.black
                                                        .withValues(alpha: 0.6),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 12,
                                              left: 14,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.55),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.25)),
                                                ),
                                                child: Text(
                                                  workout.splitType,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 12,
                                              right: 14,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color:
                                                      FormaColors.primaryAccent,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${workout.estimatedMinutes} min',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: FormaColors.charcoal,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (workout.imageUrl.isEmpty)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    workout.name,
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w800),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: FormaColors
                                                        .primaryAccent
                                                        .withValues(
                                                            alpha: 0.18),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    '${workout.estimatedMinutes} min',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          FormaColors.charcoal,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Text(
                                              workout.name,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800),
                                            ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${workout.exercises.length} exercises • ${workout.targetMuscleGroups.join(', ')}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? FormaColors
                                                      .darkSecondaryText
                                                  : FormaColors
                                                      .lightSecondaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: FormaButton(
                                                  label: 'Start Routine',
                                                  icon:
                                                      Icons.play_arrow_rounded,
                                                  onPressed: openContainer,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.edit_note_rounded),
                                                tooltip: 'Log Completed',
                                                onPressed: () {
                                                  context.push(
                                                      '/workout/manual-log',
                                                      extra: workout);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            openBuilder: (context, _) =>
                                WorkoutExecutionScreen(workout: workout),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading routines: $e'),
                ),

                const SizedBox(height: 28),

                // 4. Unified Exercise Database & AI Discovery
                const FormaSectionHeader(title: 'Exercise Library & Discovery'),
                const SizedBox(height: 14),

                // If user is searching:
                if (_exerciseSearchQuery.isNotEmpty) ...[
                  // Inline "Search Online with AI" action pill
                  FormaBounceable(
                    onTap: () {
                      ref
                          .read(exerciseDiscoveryProvider.notifier)
                          .triggerOnlineSearch(_exerciseSearchQuery);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? FormaColors.azureDark
                            : FormaColors.azurePastel,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: FormaColors.azure.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 18, color: FormaColors.azure),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search online library for "$_exerciseSearchQuery"',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FormaColors.azure,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: FormaColors.azure),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Inline Online Loading State
                  Consumer(
                    builder: (context, ref, _) {
                      final discoveryState =
                          ref.watch(exerciseDiscoveryProvider);

                      if (discoveryState.status == DiscoveryStatus.searching) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? FormaColors.charcoal
                                : FormaColors.warmCream,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: FormaColors.primaryAccent
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      FormaColors.primaryAccent),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  discoveryState.statusMessage.isNotEmpty
                                      ? discoveryState.statusMessage
                                      : 'Searching exercise library...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? FormaColors.darkPrimaryText
                                        : FormaColors.lightPrimaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (discoveryState.discoveredResults.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color:
                                    FormaColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'DISCOVERED EXERCISES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: FormaColors.success,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...discoveryState.discoveredResults.map((ex) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: ExerciseCard(
                                  exercise: ex,
                                  onTap: () {
                                    ref
                                        .read(
                                            exerciseDiscoveryProvider.notifier)
                                        .approveAndSaveExercise(ex);
                                    context.push('/workout/exercise/${ex.id}',
                                        extra: ex);
                                  },
                                  onLog: () {
                                    ref
                                        .read(
                                            exerciseDiscoveryProvider.notifier)
                                        .approveAndSaveExercise(ex);
                                    context.push('/workout/manual-log',
                                        extra: ex);
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 14),
                          ],
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),

                  // Local Matches
                  exercisesAsync.when(
                    data: (exercises) {
                      final cleanQ = _exerciseSearchQuery.toLowerCase();
                      final matches = exercises
                          .where((ex) =>
                              ex.name.toLowerCase().contains(cleanQ) ||
                              ex.primaryMuscle.toLowerCase().contains(cleanQ) ||
                              ex.equipment.toLowerCase().contains(cleanQ))
                          .toList();

                      if (matches.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No local exercise matches. Tap "Search Online & AI" above!',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? FormaColors.darkSecondaryText
                                    : FormaColors.lightSecondaryText,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: matches.map((ex) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ExerciseCard(
                              exercise: ex,
                              onTap: () {
                                context.push('/workout/exercise/${ex.id}',
                                    extra: ex);
                              },
                              onLog: () {
                                context.push('/workout/manual-log', extra: ex);
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ] else ...[
                  // Default muscle-filtered exercise list
                  exercisesAsync.when(
                    data: (exercises) {
                      var filtered = exercises;
                      if (_selectedMuscles.isNotEmpty) {
                        filtered = filtered
                            .where((e) =>
                                _selectedMuscles.contains(e.primaryMuscle))
                            .toList();
                      }
                      return Column(
                        children: filtered.map((ex) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ExerciseCard(
                              exercise: ex,
                              onTap: () {
                                context.push('/workout/exercise/${ex.id}',
                                    extra: ex);
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],

                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark
                ? FormaColors.darkBackground
                : FormaColors.lightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Completed Workouts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final historyAsync = ref.watch(workoutHistoryProvider);
                    return historyAsync.when(
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fitness_center_rounded,
                                    size: 48,
                                    color: Colors.grey.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No workouts completed yet',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Start a routine or tap "Log Workout" above to record your session.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: sessions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, index) {
                            final s = sessions[index];
                            final date = s.endTime ?? s.startTime;
                            final dateStr =
                                '${date.day}/${date.month}/${date.year}';
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? FormaColors.darkCardBackground
                                    : FormaColors.lightCardBackground,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: FormaColors.coralPink
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                        Icons.check_circle_rounded,
                                        color: FormaColors.coralPink),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.workoutName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$dateStr • ${s.duration.inMinutes} min • ${s.totalVolume.toInt()} kg',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? FormaColors.darkSecondaryText
                                                : FormaColors
                                                    .lightSecondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
