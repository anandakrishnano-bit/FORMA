import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/data/models/muscle_tracker_model.dart';
import 'package:forma/data/repositories/muscle_tracker_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

class WeeklyMusclePlanScreen extends ConsumerStatefulWidget {
  const WeeklyMusclePlanScreen({super.key});

  @override
  ConsumerState<WeeklyMusclePlanScreen> createState() =>
      _WeeklyMusclePlanScreenState();
}

class _WeeklyMusclePlanScreenState
    extends ConsumerState<WeeklyMusclePlanScreen> {
  String _selectedSplitName = 'Push / Pull / Legs';
  Map<int, DayMusclePlan> _dayPlans = {};
  bool _isSaving = false;
  bool _initialized = false;
  late DateTime _weekStart;

  final List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _weekStart = getStartOfWeek(DateTime.now());
  }

  void _applyTemplate(String templateName) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedSplitName = templateName;
      if (templateName == 'Push / Pull / Legs') {
        _dayPlans = WeeklyMusclePlan.createPPLTemplate();
      } else if (templateName == 'Upper / Lower') {
        _dayPlans = WeeklyMusclePlan.createUpperLowerTemplate();
      } else if (templateName == 'Full Body') {
        _dayPlans = WeeklyMusclePlan.createFullBodyTemplate();
      }
    });
  }

  void _showMusclePickerForDay(int dayOfWeek) {
    final current = _dayPlans[dayOfWeek]?.plannedMuscles ?? [];
    final tempSelected = Set<String>.from(current);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
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
                  const SizedBox(height: 16),
                  Text(
                    'Planned Muscles for ${_dayNames[dayOfWeek - 1]}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: isDark ? Colors.white : FormaColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: MajorMuscleGroup.all.length,
                      itemBuilder: (context, idx) {
                        final group = MajorMuscleGroup.all[idx];
                        final isSel = tempSelected.contains(group.name);

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setModalState(() {
                              if (isSel) {
                                tempSelected.remove(group.name);
                              } else {
                                tempSelected.add(group.name);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? group.color.withValues(alpha: 0.18)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel
                                    ? group.color
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : FormaColors.concreteGrey
                                            .withValues(alpha: 0.2)),
                                width: isSel ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(group.icon, size: 16, color: group.color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    group.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white
                                          : FormaColors.charcoal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSel)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: group.color,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FormaButton(
                    label: 'Done (${tempSelected.length} muscles)',
                    onPressed: () {
                      setState(() {
                        final currentDay = _dayPlans[dayOfWeek] ??
                            DayMusclePlan(dayOfWeek: dayOfWeek);
                        _dayPlans[dayOfWeek] = currentDay.copyWith(
                          plannedMuscles: tempSelected.toList(),
                          isRestDay: tempSelected.isEmpty,
                        );
                      });
                      Navigator.of(ctx).pop();
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

  Future<void> _handleSave() async {
    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(muscleTrackerRepositoryProvider);
      final plan = WeeklyMusclePlan(
        id: repo.getWeekId(_weekStart),
        userId: user.uid,
        weekStartDate: _weekStart,
        splitName: _selectedSplitName,
        dayPlans: _dayPlans,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveWeeklyPlan(plan);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Weekly split "$_selectedSplitName" saved!',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: FormaColors.charcoal,
              ),
            ),
            backgroundColor: FormaColors.primaryAccent,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save plan: $e'),
            backgroundColor: FormaColors.coralPink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentFirebaseUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
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
          'Weekly Split Planner',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal,
          ),
        ),
      ),
      body: StreamBuilder<WeeklyMusclePlan?>(
        stream: repo.streamWeeklyPlan(user.uid, _weekStart),
        builder: (context, snapshot) {
          if (!_initialized && snapshot.hasData && snapshot.data != null) {
            _initialized = true;
            _selectedSplitName = snapshot.data!.splitName;
            _dayPlans = Map.from(snapshot.data!.dayPlans);
          } else if (!_initialized &&
              snapshot.connectionState == ConnectionState.done &&
              _dayPlans.isEmpty) {
            _initialized = true;
            _dayPlans = WeeklyMusclePlan.createPPLTemplate();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: FormaSpacing.lg,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Split Template',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                ),
                const SizedBox(height: 10),

                // Template Selector Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTemplateChip(
                        'Push / Pull / Legs',
                        isDark,
                        Icons.swap_horiz_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildTemplateChip(
                        'Upper / Lower',
                        isDark,
                        Icons.height_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildTemplateChip(
                        'Full Body',
                        isDark,
                        Icons.accessibility_new_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildTemplateChip(
                        'Custom Split',
                        isDark,
                        Icons.dashboard_customize_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Day-by-Day Schedule',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                ),
                const SizedBox(height: 12),

                // 7 Days List
                ...List.generate(7, (index) {
                  final dayOfWeek = index + 1;
                  final dayPlan = _dayPlans[dayOfWeek] ??
                      DayMusclePlan(dayOfWeek: dayOfWeek);

                  return _buildDayPlanTile(
                    isDark: isDark,
                    dayOfWeek: dayOfWeek,
                    dayName: _dayNames[index],
                    dayPlan: dayPlan,
                  );
                }),
                const SizedBox(height: 24),

                FormaButton(
                  label: 'Save Weekly Split',
                  onPressed: _isSaving ? null : _handleSave,
                  isLoading: _isSaving,
                  icon: Icons.check_rounded,
                ),
                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateChip(String name, bool isDark, IconData icon) {
    final isSelected = _selectedSplitName == name;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? FormaColors.charcoal : FormaColors.primaryAccent,
      ),
      label: Text(
        name,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected
              ? FormaColors.charcoal
              : (isDark ? Colors.white70 : FormaColors.charcoal),
        ),
      ),
      selected: isSelected,
      selectedColor: FormaColors.primaryAccent,
      backgroundColor: isDark ? FormaColors.charcoal : Colors.white,
      onSelected: (selected) {
        if (selected) _applyTemplate(name);
      },
    );
  }

  Widget _buildDayPlanTile({
    required bool isDark,
    required int dayOfWeek,
    required String dayName,
    required DayMusclePlan dayPlan,
  }) {
    final isRest = dayPlan.isRestDay;

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
                dayName,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : FormaColors.charcoal,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Rest Day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: isRest,
                    activeThumbColor: FormaColors.primaryAccent,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _dayPlans[dayOfWeek] = dayPlan.copyWith(
                          isRestDay: val,
                          plannedMuscles: val ? [] : dayPlan.plannedMuscles,
                          label: val ? 'Rest Day' : dayPlan.label,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          if (!isRest) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: dayPlan.plannedMuscles.isEmpty
                        ? [
                            Text(
                              'No muscles selected yet',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: FormaColors.concreteGrey,
                              ),
                            ),
                          ]
                        : dayPlan.plannedMuscles.map((m) {
                            final group = MajorMuscleGroup.fromName(m);
                            final color =
                                group?.color ?? FormaColors.primaryAccent;
                            return Chip(
                              label: Text(m),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : FormaColors.charcoal,
                              ),
                              backgroundColor: color.withValues(alpha: 0.15),
                              side: BorderSide(
                                color: color.withValues(alpha: 0.35),
                              ),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showMusclePickerForDay(dayOfWeek),
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: FormaColors.primaryAccent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
