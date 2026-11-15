import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/daily_summary_model.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/models/workout_session_model.dart';
import 'package:forma/data/repositories/daily_summary_repository.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/data/repositories/workout_repository.dart';

/// Activity Calendar for FORMA.
///
/// Features:
/// - Full monthly historical calendar with previous/next month navigation & Today jump.
/// - Semantic multi-dot indicators per day:
///   * Coral (#F27689): Workout logged
///   * Golden Yellow (#FFC443): Nutrition logged
///   * Icy Blue (#C5D0DE): Habits completed
///   * Sage Green (#9CAF88): Verified activity / steps
///   * Charcoal (#171719): Personal expenses recorded
/// - Day breakdown details for the active selected day.
/// - ZERO FAKE DATA GUARANTEE: Derives status purely from verified user records.
class ActivityCalendarScreen extends ConsumerStatefulWidget {
  const ActivityCalendarScreen({super.key});

  @override
  ConsumerState<ActivityCalendarScreen> createState() =>
      _ActivityCalendarScreenState();
}

class _ActivityCalendarScreenState
    extends ConsumerState<ActivityCalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    setState(() {
      _selectedDay = DateTime(now.year, now.month, now.day);
      _displayedMonth = DateTime(now.year, now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch all data sources
    final workoutHistoryAsync = ref.watch(workoutHistoryProvider);
    final expensesAsync = ref.watch(personalExpensesStreamProvider);
    final recentSummariesAsync = ref.watch(recentDailySummariesProvider);

    final workouts = workoutHistoryAsync.valueOrNull ?? [];
    final expenses = expensesAsync.valueOrNull ?? [];
    final summaries = recentSummariesAsync.valueOrNull ?? [];

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Home',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            'Activity Calendar',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            TextButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today_rounded,
                  size: 16, color: FormaColors.goldenYellow),
              label: const Text(
                'Today',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: FormaColors.goldenYellow),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Switcher Header
                _buildMonthHeader(isDark),
                const SizedBox(height: 12),

                // Calendar Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? FormaColors.charcoal : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : FormaColors.divider.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Weekday Labels
                      _buildWeekdayLabels(isDark),
                      const SizedBox(height: 8),

                      // Month Grid
                      _buildMonthGrid(
                        isDark: isDark,
                        workouts: workouts,
                        expenses: expenses,
                        summaries: summaries,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Dot Legend Bar
                _buildDotLegend(isDark),

                const SizedBox(height: 24),

                // Day Breakdown Section
                _buildDayDetailBreakdown(
                  selectedDay: _selectedDay,
                  isDark: isDark,
                  workouts: workouts,
                  expenses: expenses,
                  summaries: summaries,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(bool isDark) {
    final title = DateFormat('MMMM yyyy').format(_displayedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark
                ? FormaColors.darkPrimaryText
                : FormaColors.lightPrimaryText,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              onPressed: _previousMonth,
              tooltip: 'Previous month',
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              onPressed: _nextMonth,
              tooltip: 'Next month',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels(bool isDark) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: labels.map((l) {
        return SizedBox(
          width: 38,
          child: Center(
            child: Text(
              l,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGrid({
    required bool isDark,
    required List<WorkoutSessionModel> workouts,
    required List<PersonalExpense> expenses,
    required List<DailySummary> summaries,
  }) {
    final firstDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;

    // weekday is 1 for Mon, 7 for Sun
    final startingOffset = firstDayOfMonth.weekday - 1;
    final totalCells = ((startingOffset + daysInMonth + 6) ~/ 7) * 7;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final rows = <Widget>[];
    List<Widget> currentRow = [];

    for (int i = 0; i < totalCells; i++) {
      final dayNumber = i - startingOffset + 1;
      final isCurrentMonth = dayNumber >= 1 && dayNumber <= daysInMonth;

      if (!isCurrentMonth) {
        // Empty placeholder cell
        currentRow.add(const SizedBox(width: 38, height: 50));
      } else {
        final cellDate =
            DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
        final isSelected = cellDate.year == _selectedDay.year &&
            cellDate.month == _selectedDay.month &&
            cellDate.day == _selectedDay.day;
        final isToday = cellDate.isAtSameMomentAs(today);

        // Compute semantic indicator dots
        final hasWorkout = workouts.any((w) =>
            w.startTime.year == cellDate.year &&
            w.startTime.month == cellDate.month &&
            w.startTime.day == cellDate.day);

        final hasExpense = expenses.any((e) =>
            e.date.year == cellDate.year &&
            e.date.month == cellDate.month &&
            e.date.day == cellDate.day);

        final dateStr = DateFormat('yyyy-MM-dd').format(cellDate);
        final summary = summaries.where((s) => s.date == dateStr).firstOrNull;

        final hasNutrition = (summary != null && summary.consumedCalories > 0);
        final hasHabits = (summary != null &&
            summary.habitsSummary.isNotEmpty &&
            !summary.habitsSummary.contains('No habits'));
        final hasActivity = (summary != null && summary.steps > 0);

        currentRow.add(
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDay = cellDate);
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 38,
              height: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FormaColors.goldenYellow
                          : (isToday
                              ? (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE8E5DD))
                              : Colors.transparent),
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(
                              color: FormaColors.goldenYellow, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? FormaColors.charcoal
                              : (isDark
                                  ? FormaColors.darkPrimaryText
                                  : FormaColors.lightPrimaryText),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Dots row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasWorkout) _buildDot(FormaColors.coralPink),
                      if (hasNutrition) _buildDot(FormaColors.goldenYellow),
                      if (hasHabits) _buildDot(FormaColors.secondaryAccent),
                      if (hasActivity) _buildDot(FormaColors.semanticSteps),
                      if (hasExpense)
                        _buildDot(
                            isDark ? Colors.white70 : FormaColors.charcoal),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }

      if (currentRow.length == 7) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.from(currentRow),
            ),
          ),
        );
        currentRow = [];
      }
    }

    return Column(children: rows);
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 0.8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDotLegend(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.charcoal.withValues(alpha: 0.5)
            : const Color(0xFFF0EDE5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildLegendItem(FormaColors.coralPink, 'Workout', isDark),
            const SizedBox(width: 14),
            _buildLegendItem(FormaColors.goldenYellow, 'Nutrition', isDark),
            const SizedBox(width: 14),
            _buildLegendItem(FormaColors.secondaryAccent, 'Habits', isDark),
            const SizedBox(width: 14),
            _buildLegendItem(
                FormaColors.semanticSteps, 'Steps/Activity', isDark),
            const SizedBox(width: 14),
            _buildLegendItem(isDark ? Colors.white70 : FormaColors.charcoal,
                'Expense', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildDayDetailBreakdown({
    required DateTime selectedDay,
    required bool isDark,
    required List<WorkoutSessionModel> workouts,
    required List<PersonalExpense> expenses,
    required List<DailySummary> summaries,
  }) {
    final dayLabel = DateFormat('EEEE, d MMMM yyyy').format(selectedDay);

    final dayWorkouts = workouts
        .where((w) =>
            w.startTime.year == selectedDay.year &&
            w.startTime.month == selectedDay.month &&
            w.startTime.day == selectedDay.day)
        .toList();

    final dayExpenses = expenses
        .where((e) =>
            e.date.year == selectedDay.year &&
            e.date.month == selectedDay.month &&
            e.date.day == selectedDay.day)
        .toList();

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final summary = summaries.where((s) => s.date == dateStr).firstOrNull;

    final totalExpenseAmount =
        dayExpenses.fold(0.0, (acc, e) => acc + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayLabel,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark
                ? FormaColors.darkPrimaryText
                : FormaColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 12),

        // 1. Workout Card
        _buildDetailCard(
          isDark: isDark,
          icon: Icons.fitness_center_rounded,
          iconColor: FormaColors.coralPink,
          title: 'Workouts & Training',
          child: dayWorkouts.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dayWorkouts.map((session) {
                    final durationMins = session.duration.inMinutes;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.workoutName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                          Text(
                            '$durationMins min • ${session.exercises.length} exercises',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? FormaColors.darkSecondaryText
                                  : FormaColors.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              : Text(
                  'No workout logged for this day.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // 2. Nutrition Card
        _buildDetailCard(
          isDark: isDark,
          icon: Icons.restaurant_rounded,
          iconColor: FormaColors.goldenYellow,
          title: 'Nutrition',
          child: summary != null && summary.consumedCalories > 0
              ? Text(
                  '${summary.consumedCalories.toInt()} kcal recorded • ${summary.nutritionSummary}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                )
              : Text(
                  'No meals logged for this day.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // 3. Habits Card
        _buildDetailCard(
          isDark: isDark,
          icon: Icons.check_circle_rounded,
          iconColor: FormaColors.secondaryAccent,
          title: 'Daily Habits',
          child: summary != null && summary.habitsSummary.isNotEmpty
              ? Text(
                  summary.habitsSummary,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                )
              : Text(
                  'No habit activity recorded.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // 4. Activity & Energy Score Card
        _buildDetailCard(
          isDark: isDark,
          icon: Icons.bolt_rounded,
          iconColor: FormaColors.semanticSteps,
          title: 'Activity & Energy',
          child: summary != null && summary.hasSufficientData
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            FormaColors.semanticSteps.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Score: ${summary.energyScore ?? "--"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: FormaColors.semanticSteps,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${summary.steps} steps • ${summary.activeCalories.toInt()} active kcal',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ],
                )
              : Text(
                  'No step or activity telemetry recorded.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // 5. Personal Spending Card
        _buildDetailCard(
          isDark: isDark,
          icon: Icons.account_balance_wallet_rounded,
          iconColor: isDark ? Colors.white70 : FormaColors.charcoal,
          title: 'Private Expenses',
          child: dayExpenses.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ₹${totalExpenseAmount.toStringAsFixed(0)} across ${dayExpenses.length} purchase(s)',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    ...dayExpenses.take(3).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.title,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '₹${e.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? FormaColors.goldenYellow
                                      : FormaColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (dayExpenses.length > 3)
                      Text(
                        '+ ${dayExpenses.length - 3} more item(s)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
                      ),
                  ],
                )
              : Text(
                  'No expenses recorded on this date.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : FormaColors.divider.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
