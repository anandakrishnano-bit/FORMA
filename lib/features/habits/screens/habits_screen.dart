import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/components/calendar_widget.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/habit_card.dart';
import 'package:forma/core/components/section_header.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/forma_easings.dart';
import 'package:forma/data/models/habit.dart';
import 'package:forma/data/repositories/habit_repository.dart';

/// Inspiring Habits & Metrics Dashboard.
///
/// Built strictly with ZERO fake data:
/// - True date-keyed habit tracking: switching days updates the checklist for that specific date.
/// - Dynamic weekly consistency score computed directly from genuine logs.
/// - 7 Days vs 4 Weeks vertical capsule pill bar chart (Mon-Sun or W1-W4) showing real percentages.
/// - Dynamic streak and monthly task totals computed from stored records.
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  DateTime _selectedDate = DateTime.now();
  int _graphViewIndex = 0; // 0: 7 Days (Mon-Sun), 1: 4 Weeks (W1-W4)

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitsAsync = ref.watch(habitsListProvider);

    // Watch habitRecordsProvider to rebuild whenever ANY habit on ANY date is toggled
    ref.watch(habitRecordsProvider);
    final repo = ref.read(habitRepositoryProvider);

    final statusForSelectedDate = repo.getStatusForDate(_selectedDate);
    final weekPercentages = repo.getWeeklyDayPercentages(_selectedDate);
    final weeklyAverage = weekPercentages.isNotEmpty
        ? (weekPercentages.reduce((a, b) => a + b) / 7).round()
        : 0;
    final activeDaysThisWeek = weekPercentages.where((p) => p > 0).length;
    final currentStreak = repo.calculateCurrentStreak();
    final monthlyTasks = repo.getMonthlyCompletedTasks(_selectedDate);

    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final dayLabel = isToday
        ? "Today's Checklist"
        : '${_weekdayName(_selectedDate.weekday)}, ${_selectedDate.day} ${_monthName(_selectedDate.month)}';

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('Habits & Metrics',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Pick Date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: isDark
                        ? ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: FormaColors.primaryAccent,
                              onPrimary: FormaColors.charcoal,
                              surface: FormaColors.darkCardBackground,
                            ),
                          )
                        : ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: FormaColors.primaryAccent,
                              onPrimary: FormaColors.charcoal,
                            ),
                          ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            icon: const Icon(Icons.calendar_month_rounded),
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: FormaColors.primaryAccent,
          onRefresh: () async {
            ref.invalidate(habitsListProvider);
            ref.invalidate(habitRecordsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Weekly Calendar Selector Strip
                FormaCalendar(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() => _selectedDate = date);
                  },
                ),

                const SizedBox(height: 24),

                // 2. PROMINENT CONSISTENCY METRIC CARD (Zero Fake Data)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color:
                        isDark ? FormaColors.charcoal : FormaColors.warmCream,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: FormaColors.primaryAccent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: FormaColors.primaryAccent
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'WEEKLY CONSISTENCY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: FormaColors.goldenYellow,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: FormaColors.terracotta,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.local_fire_department_rounded,
                                size: 16,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$weeklyAverage%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? FormaColors.darkPrimaryText
                                  : FormaColors.lightPrimaryText,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeDaysThisWeek > 0
                                      ? '$activeDaysThisWeek of 7 days target hit'
                                      : 'No habit logs recorded this week',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? FormaColors.darkPrimaryText
                                        : FormaColors.lightPrimaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentStreak > 0
                                      ? 'Current streak: $currentStreak days'
                                      : 'Complete daily habits to build your streak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? FormaColors.darkSecondaryText
                                        : FormaColors.lightSecondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. VISUAL CAPSULE PILL BAR GRAPH (Days vs Weeks)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        isDark ? FormaColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(28),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _graphViewIndex == 0
                                ? '7 Days Breakdown'
                                : '4 Weeks Trend',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? FormaColors.darkPrimaryText
                                  : FormaColors.lightPrimaryText,
                            ),
                          ),
                          // View Switcher Capsule (Days vs Weeks)
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? FormaColors.charcoal
                                  : FormaColors.warmCream,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _buildTogglePill('Days', _graphViewIndex == 0,
                                    () {
                                  setState(() => _graphViewIndex = 0);
                                }),
                                const SizedBox(width: 4),
                                _buildTogglePill('Weeks', _graphViewIndex == 1,
                                    () {
                                  setState(() => _graphViewIndex = 1);
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Chart Body: Days vs Weeks (Default Bars style)
                      AnimatedSwitcher(
                        duration: FormaEasings.normal,
                        switchInCurve: FormaEasings.easeOutCubic,
                        switchOutCurve: FormaEasings.easeOutCubic,
                        child: _graphViewIndex == 0
                            ? _build7DaysBarChart(isDark, repo)
                            : _build4WeeksBarChart(isDark, repo),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. BENTO METRICS SUMMARY ROW (Zero Fake Data)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? FormaColors.terracottaDark
                              : FormaColors.terracottaPastel,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: FormaColors.terracotta
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: FormaColors.terracotta,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bolt_rounded,
                                  size: 16, color: Colors.white),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '$currentStreak ${currentStreak == 1 ? "Day" : "Days"}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: FormaColors.terracotta),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Active Streak',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : FormaColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? FormaColors.sageDark
                              : FormaColors.sagePastel,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: FormaColors.sage.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: FormaColors.sage,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.task_alt_rounded,
                                  size: 16, color: Colors.white),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '$monthlyTasks ${monthlyTasks == 1 ? "Task" : "Tasks"}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: FormaColors.sage),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Done this month',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : FormaColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 5. HABITS CHECKLIST (Tied strictly to _selectedDate)
                FormaSectionHeader(
                  title: dayLabel,
                  actionLabel: '+ Add Habit',
                  onAction: () => _showAddHabitDialog(context),
                ),
                const SizedBox(height: 16),

                habitsAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? FormaColors.darkCardBackground
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Text(
                              'No habits created yet. Tap + Add Habit to start!'),
                        ),
                      );
                    }

                    return Column(
                      children: habits.map((habit) {
                        final isCompleted =
                            statusForSelectedDate[habit.id] ?? false;
                        return HabitCard(
                          habit: habit,
                          isCompleted: isCompleted,
                          onToggle: () {
                            ref
                                .read(habitRecordsProvider.notifier)
                                .toggleHabit(habit.id, _selectedDate);
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading habits: $e'),
                ),

                const SizedBox(height: 24),
                FormaButton(
                  label: '+ Add Custom Habit',
                  onPressed: () => _showAddHabitDialog(context),
                ),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTogglePill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? FormaColors.primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? FormaColors.charcoal : FormaColors.concreteGrey,
          ),
        ),
      ),
    );
  }

  /// Weekly 7-day default bar chart (Mon-Sun) computed from real logs
  Widget _build7DaysBarChart(bool isDark, HabitRepository repo) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final percentages = repo.getWeeklyDayPercentages(_selectedDate);
    final colors = [
      FormaColors.terracotta,
      FormaColors.goldenYellow,
      FormaColors.sage,
      FormaColors.azure,
      FormaColors.lavender,
      FormaColors.terracotta,
      FormaColors.goldenYellow,
    ];

    return KeyedSubtree(
      key: const ValueKey('7days_chart'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          return _buildDefaultBar(
            percentage: percentages[i],
            label: days[i],
            color: colors[i],
            isDark: isDark,
            height: 130,
            width: 22,
          );
        }),
      ),
    );
  }

  /// 4-week monthly trend default bar chart (W1-W4) computed from real logs
  Widget _build4WeeksBarChart(bool isDark, HabitRepository repo) {
    final weeks = ['W1', 'W2', 'W3', 'W4'];
    final percentages = repo.getMonthlyWeekPercentages(_selectedDate);
    final colors = [
      FormaColors.azure,
      FormaColors.sage,
      FormaColors.terracotta,
      FormaColors.goldenYellow,
    ];

    return KeyedSubtree(
      key: const ValueKey('4weeks_chart'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          return _buildDefaultBar(
            percentage: percentages[i],
            label: weeks[i],
            color: colors[i],
            isDark: isDark,
            height: 130,
            width: 44,
          );
        }),
      ),
    );
  }

  /// Default Standard Bar Chart Column (Vertical rectangular bar with rounded top corners on baseline)
  Widget _buildDefaultBar({
    required int percentage,
    required String label,
    required Color color,
    required bool isDark,
    required double height,
    required double width,
  }) {
    final fillRatio = (percentage / 100.0).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Percentage indicator above bar
        SizedBox(
          height: 18,
          child: Text(
            percentage > 0 ? '$percentage%' : '0%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: percentage > 0
                  ? color
                  : (isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.concreteGrey),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Default Bar Track with rising filled bar using https://easings.net/#easeOutExpo
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isDark ? FormaColors.charcoal : const Color(0xFFF0EDE6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          alignment: Alignment.bottomCenter,
          child: AnimatedFractionallySizedBox(
            duration: FormaEasings.medium,
            curve: FormaEasings.easeOutExpo, // https://easings.net/#easeOutExpo
            alignment: Alignment.bottomCenter,
            heightFactor: fillRatio,
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
          ),
        ),

        // Horizontal baseline beneath bar
        Container(
          width: width + 8,
          height: 2,
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        const SizedBox(height: 8),

        // Day / Week Label
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
        ),
      ],
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final titleController = TextEditingController();
    int selectedColor = 0xFF88A95C;
    int selectedIcon = 0xe28d;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? FormaColors.darkBackground
                    : FormaColors.lightBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: FormaColors.concreteGrey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Create Custom Habit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 10k Daily Steps, Read 15 mins...',
                      filled: true,
                      fillColor: isDark ? FormaColors.charcoal : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose Color Theme',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      0xFF88A95C, // sage
                      0xFFFFBD35, // yellow
                      0xFFE98557, // terracotta
                      0xFF6C8CBA, // azure
                      0xFFA685B8, // lavender
                    ].map((col) {
                      final isSelected = selectedColor == col;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = col),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(col),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color:
                                            Color(col).withValues(alpha: 0.5),
                                        blurRadius: 8)
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 20, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose Icon',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      0xe28d, // fitness_center
                      0xe3e0, // water_drop
                      0xe532, // restaurant
                      0xf3ea, // directions_run
                      0xe08f, // bed
                    ].map((ic) {
                      final isSelected = selectedIcon == ic;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = ic),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? FormaColors.primaryAccent
                                : (isDark
                                    ? FormaColors.charcoal
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            // ignore: non_const_argument_for_const_parameter
                            IconData(ic, fontFamily: 'MaterialIcons'),
                            color: isSelected
                                ? FormaColors.charcoal
                                : (isDark
                                    ? Colors.white70
                                    : FormaColors.charcoal),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FormaButton(
                    label: 'Save Habit',
                    isFullWidth: true,
                    onPressed: () async {
                      final text = titleController.text.trim();
                      if (text.isNotEmpty) {
                        final newHabit = Habit(
                          id: 'h_${DateTime.now().millisecondsSinceEpoch}',
                          userId: 'user_local',
                          title: text,
                          iconCodePoint: selectedIcon,
                          colorValue: selectedColor,
                          frequency: 'Daily',
                          streakCount: 0,
                          createdAt: DateTime.now(),
                        );
                        await ref
                            .read(habitRepositoryProvider)
                            .addHabit(newHabit);
                        ref
                            .read(habitRecordsProvider.notifier)
                            .toggleHabit(newHabit.id, _selectedDate);
                        ref.invalidate(habitsListProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1) % 7];
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[(month - 1) % 12];
  }
}
