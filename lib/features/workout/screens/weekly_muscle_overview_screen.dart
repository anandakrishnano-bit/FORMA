import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';
import 'package:forma/data/models/muscle_tracker_model.dart';
import 'package:forma/data/repositories/muscle_tracker_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

class WeeklyMuscleOverviewScreen extends ConsumerStatefulWidget {
  const WeeklyMuscleOverviewScreen({super.key});

  @override
  ConsumerState<WeeklyMuscleOverviewScreen> createState() =>
      _WeeklyMuscleOverviewScreenState();
}

class _WeeklyMuscleOverviewScreenState
    extends ConsumerState<WeeklyMuscleOverviewScreen> {
  late DateTime _selectedWeekStart;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedWeekStart = getStartOfWeek(now);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _previousWeek() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
      _selectedDate = _selectedWeekStart;
    });
  }

  void _nextWeek() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
      _selectedDate = _selectedWeekStart;
    });
  }

  void _jumpToCurrentWeek() {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    setState(() {
      _selectedWeekStart = getStartOfWeek(now);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  bool get _isCurrentWeek {
    final nowWeekStart = getStartOfWeek(DateTime.now());
    return _selectedWeekStart.year == nowWeekStart.year &&
        _selectedWeekStart.month == nowWeekStart.month &&
        _selectedWeekStart.day == nowWeekStart.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentFirebaseUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        appBar: AppBar(
          title: const Text('Weekly Muscle Tracker'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('Sign in to view your muscle plan.')),
      );
    }

    final repo = ref.watch(muscleTrackerRepositoryProvider);

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Muscle Tracker',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Body & Activity Visualization',
            icon: const Icon(
              Icons.accessibility_new_rounded,
              color: FormaColors.primaryAccent,
            ),
            onPressed: () => context.push('/workout/body-visualization'),
          ),
          IconButton(
            tooltip: 'Edit Weekly Plan',
            icon: Icon(
              Icons.tune_rounded,
              color: isDark ? Colors.white70 : FormaColors.charcoal,
            ),
            onPressed: () => context.push('/workout/muscle-plan'),
          ),
        ],
      ),
      body: StreamBuilder<List<MuscleTrainingLog>>(
        stream: repo.streamWeekTrainingLogs(user.uid, _selectedWeekStart),
        builder: (context, logsSnapshot) {
          final logs = logsSnapshot.data ?? [];

          return StreamBuilder<WeeklyMusclePlan?>(
            stream: repo.streamWeeklyPlan(user.uid, _selectedWeekStart),
            builder: (context, planSnapshot) {
              final plan = planSnapshot.data ??
                  WeeklyMusclePlan(
                    id: repo.getWeekId(_selectedWeekStart),
                    userId: user.uid,
                    weekStartDate: _selectedWeekStart,
                    splitName: 'Push / Pull / Legs',
                    dayPlans: WeeklyMusclePlan.createPPLTemplate(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

              final status = MuscleTrackerRepository.computeWeeklyMuscleStatus(
                plan: plan,
                logs: logs,
                today: _isCurrentWeek ? DateTime.now() : _selectedWeekStart,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: FormaSpacing.lg,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Week Switcher Bar ──
                    _buildWeekSwitcherBar(isDark),
                    const SizedBox(height: 18),

                    // ── 7-Day Horizontal Strip ──
                    _buildSevenDayStrip(isDark, logs, plan),
                    const SizedBox(height: 24),

                    // ── Summary Cards: Trained vs Remaining ──
                    _buildStatusOverviewCards(isDark, status, plan),
                    const SizedBox(height: 24),

                    // ── Selected Day Breakdown ──
                    _buildSelectedDaySection(isDark, logs, plan),
                    const SizedBox(height: 24),

                    // ── Remaining This Week Section ──
                    _buildRemainingMusclesSection(isDark, status),
                    const SizedBox(height: 36),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workout/muscle-log'),
        backgroundColor: FormaColors.primaryAccent,
        foregroundColor: FormaColors.charcoal,
        elevation: 3,
        icon: const Icon(Icons.add_task_rounded, size: 20),
        label: Text(
          'Log Muscles',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekSwitcherBar(bool isDark) {
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    final rangeText =
        '${DateFormat('MMM d').format(_selectedWeekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : FormaColors.concreteGrey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _previousWeek,
            tooltip: 'Previous week',
          ),
          Column(
            children: [
              Text(
                rangeText,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : FormaColors.charcoal,
                ),
              ),
              if (!_isCurrentWeek)
                GestureDetector(
                  onTap: _jumpToCurrentWeek,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Jump to Today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FormaColors.primaryAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _nextWeek,
            tooltip: 'Next week',
          ),
        ],
      ),
    );
  }

  Widget _buildSevenDayStrip(
    bool isDark,
    List<MuscleTrainingLog> logs,
    WeeklyMusclePlan plan,
  ) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayDate = _selectedWeekStart.add(Duration(days: index));
        final dayOfWeek = index + 1; // 1 = Monday
        final isSelected = dayDate.year == _selectedDate.year &&
            dayDate.month == _selectedDate.month &&
            dayDate.day == _selectedDate.day;

        final isToday = dayDate.year == DateTime.now().year &&
            dayDate.month == DateTime.now().month &&
            dayDate.day == DateTime.now().day;

        // Check if logs exist for this date
        final hasLogs = logs.any((l) =>
            l.workoutDate.year == dayDate.year &&
            l.workoutDate.month == dayDate.month &&
            l.workoutDate.day == dayDate.day);

        final dayPlan = plan.dayPlans[dayOfWeek];
        final isRest = dayPlan?.isRestDay ?? false;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDate = dayDate);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? FormaColors.primaryAccent
                      : (isDark
                          ? FormaColors.charcoal.withValues(alpha: 0.6)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? FormaColors.primaryAccent
                        : (isToday
                            ? FormaColors.goldenYellow
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : FormaColors.concreteGrey
                                    .withValues(alpha: 0.2))),
                    width: isToday && !isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      dayNames[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? FormaColors.charcoal
                            : (isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${dayDate.day}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? FormaColors.charcoal
                            : (isDark ? Colors.white : FormaColors.charcoal),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status indicator dot
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasLogs
                            ? (isSelected
                                ? FormaColors.charcoal
                                : const Color(
                                    0xFF659253)) // Sage green = trained
                            : (isRest
                                ? (isSelected
                                    ? FormaColors.charcoal
                                        .withValues(alpha: 0.4)
                                    : FormaColors.concreteGrey
                                        .withValues(alpha: 0.5))
                                : Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatusOverviewCards(
    bool isDark,
    ({
      Set<String> trainedMuscles,
      Set<String> plannedRemainingMuscles,
      Set<String> allWeeklyPlanned,
      int daysTrainedCount,
      int restDaysCount,
    }) status,
    WeeklyMusclePlan plan,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : FormaColors.concreteGrey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Split: ${plan.splitName}',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isDark ? Colors.white : FormaColors.charcoal,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FormaColors.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${status.trainedMuscles.length}/${status.allWeeklyPlanned.length} Groups',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: FormaColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniMetric(
                label: 'Trained',
                count: '${status.trainedMuscles.length}',
                color: const Color(0xFF659253),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildMiniMetric(
                label: 'Remaining',
                count: '${status.plannedRemainingMuscles.length}',
                color: FormaColors.coralPink,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildMiniMetric(
                label: 'Days Active',
                count: '${status.daysTrainedCount}',
                color: FormaColors.goldenYellow,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildMiniMetric(
                label: 'Rest Days',
                count: '${status.restDaysCount}',
                color: FormaColors.concreteGrey,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String count,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : FormaColors.charcoal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDaySection(
    bool isDark,
    List<MuscleTrainingLog> logs,
    WeeklyMusclePlan plan,
  ) {
    final dayOfWeek = _selectedDate.weekday; // 1 = Mon
    final dayPlan = plan.dayPlans[dayOfWeek];
    final dateFormatted = DateFormat('EEEE, MMM d').format(_selectedDate);

    final dayLogs = logs
        .where((l) =>
            l.workoutDate.year == _selectedDate.year &&
            l.workoutDate.month == _selectedDate.month &&
            l.workoutDate.day == _selectedDate.day)
        .toList();

    final allTrainedMusclesForDay = <String>{};
    for (final l in dayLogs) {
      allTrainedMusclesForDay.addAll(l.muscleGroups);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormatted,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                ),
                if (dayPlan?.label != null && dayPlan!.label!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Plan: ${dayPlan.label!}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FormaColors.primaryAccent,
                      ),
                    ),
                  ),
              ],
            ),
            if (dayPlan?.isRestDay ?? false)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FormaColors.concreteGrey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Rest Day',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FormaColors.concreteGrey,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // If workouts were logged
        if (dayLogs.isNotEmpty) ...[
          ...dayLogs.map((log) => _buildDayLogCard(isDark, log)),
        ] else if (dayPlan?.isRestDay ?? false) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? FormaColors.charcoal.withValues(alpha: 0.5)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : FormaColors.concreteGrey.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hotel_rounded,
                  color: FormaColors.concreteGrey,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Scheduled rest and active recovery day.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // No workouts logged yet for this planned day
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? FormaColors.charcoal.withValues(alpha: 0.5)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : FormaColors.concreteGrey.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.fitness_center_outlined,
                      size: 20,
                      color: FormaColors.concreteGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No muscle logs recorded yet for this date.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
                if (dayPlan != null && dayPlan.plannedMuscles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Planned for today:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : FormaColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: dayPlan.plannedMuscles.map((muscle) {
                      return Chip(
                        label: Text(muscle),
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        backgroundColor:
                            FormaColors.coralPink.withValues(alpha: 0.12),
                        side: BorderSide(
                          color: FormaColors.coralPink.withValues(alpha: 0.3),
                        ),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayLogCard(bool isDark, MuscleTrainingLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : FormaColors.concreteGrey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log.workoutTitle ?? 'Muscle Training Session',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isDark ? Colors.white : FormaColors.charcoal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF659253).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.source == 'auto_workout' ? 'Auto Workout' : 'Manual',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF659253),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Muscle Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: log.muscleGroups.map((m) {
              final group = MajorMuscleGroup.fromName(m);
              final color = group?.color ?? FormaColors.primaryAccent;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      group?.icon ?? Icons.fitness_center_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      m,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : FormaColors.charcoal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          if (log.contributingExercises.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Exercises: ${log.contributingExercises.join(', ')}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
            ),
          ],

          if (log.note != null && log.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Note: ${log.note!}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : FormaColors.charcoal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRemainingMusclesSection(
    bool isDark,
    ({
      Set<String> trainedMuscles,
      Set<String> plannedRemainingMuscles,
      Set<String> allWeeklyPlanned,
      int daysTrainedCount,
      int restDaysCount,
    }) status,
  ) {
    final remaining = status.plannedRemainingMuscles;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : FormaColors.concreteGrey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: FormaColors.coralPink,
              ),
              const SizedBox(width: 8),
              Text(
                'Remaining This Week',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : FormaColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Muscle groups planned in your weekly split that are still to be trained.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 14),
          if (remaining.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF659253).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF659253),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All planned muscle groups for this week have been trained!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF659253),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: remaining.map((m) {
                final group = MajorMuscleGroup.fromName(m);
                final color = group?.color ?? FormaColors.coralPink;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        group?.icon ?? Icons.fitness_center_rounded,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: isDark ? Colors.white : FormaColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
