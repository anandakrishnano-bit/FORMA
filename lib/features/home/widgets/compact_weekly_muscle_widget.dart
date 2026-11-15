import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/muscle_tracker_model.dart';
import 'package:forma/data/repositories/muscle_tracker_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

class CompactWeeklyMuscleWidget extends ConsumerWidget {
  const CompactWeeklyMuscleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentFirebaseUserProvider);

    if (user == null) return const SizedBox.shrink();

    final repo = ref.watch(muscleTrackerRepositoryProvider);
    final weekStart = getStartOfWeek(DateTime.now());

    return StreamBuilder<List<MuscleTrainingLog>>(
      stream: repo.streamWeekTrainingLogs(user.uid, weekStart),
      builder: (context, logsSnapshot) {
        final logs = logsSnapshot.data ?? [];

        return StreamBuilder<WeeklyMusclePlan?>(
          stream: repo.streamWeeklyPlan(user.uid, weekStart),
          builder: (context, planSnapshot) {
            final plan = planSnapshot.data ??
                WeeklyMusclePlan(
                  id: repo.getWeekId(weekStart),
                  userId: user.uid,
                  weekStartDate: weekStart,
                  splitName: 'Push / Pull / Legs',
                  dayPlans: WeeklyMusclePlan.createPPLTemplate(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

            final status = MuscleTrackerRepository.computeWeeklyMuscleStatus(
              plan: plan,
              logs: logs,
              today: DateTime.now(),
            );

            final trainedCount = status.trainedMuscles.length;
            final totalPlanned = status.allWeeklyPlanned.length;
            final remainingMuscles = status.plannedRemainingMuscles;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/workout/muscle-overview');
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : FormaColors.concreteGrey.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: FormaColors.primaryAccent
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                size: 16,
                                color: FormaColors.primaryAccent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Weekly Muscle Split',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white
                                    : FormaColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '$trainedCount/$totalPlanned Groups',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: FormaColors.primaryAccent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: isDark
                                  ? Colors.white54
                                  : FormaColors.concreteGrey,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 7-day compact dot strip
                    _buildCompactDayStrip(isDark, weekStart, logs, plan),
                    const SizedBox(height: 14),

                    // Remaining / Status line
                    Row(
                      children: [
                        Icon(
                          remainingMuscles.isEmpty
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          size: 14,
                          color: remainingMuscles.isEmpty
                              ? const Color(0xFF659253)
                              : FormaColors.coralPink,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            remainingMuscles.isEmpty
                                ? 'All planned muscle groups trained this week!'
                                : 'Remaining: ${remainingMuscles.take(3).join(', ')}${remainingMuscles.length > 3 ? ' +${remainingMuscles.length - 3} more' : ''}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: remainingMuscles.isEmpty
                                  ? const Color(0xFF659253)
                                  : (isDark
                                      ? Colors.white70
                                      : FormaColors.charcoal),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactDayStrip(
    bool isDark,
    DateTime weekStart,
    List<MuscleTrainingLog> logs,
    WeeklyMusclePlan plan,
  ) {
    final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayDate = weekStart.add(Duration(days: index));
        final dayOfWeek = index + 1;
        final isToday = dayDate.year == now.year &&
            dayDate.month == now.month &&
            dayDate.day == now.day;

        final hasLogs = logs.any((l) =>
            l.workoutDate.year == dayDate.year &&
            l.workoutDate.month == dayDate.month &&
            l.workoutDate.day == dayDate.day);

        final dayPlan = plan.dayPlans[dayOfWeek];
        final isRest = dayPlan?.isRestDay ?? false;

        return Column(
          children: [
            Text(
              dayLetters[index],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                color: isToday
                    ? FormaColors.goldenYellow
                    : (isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasLogs
                    ? const Color(0xFF659253)
                    : (isRest
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : FormaColors.concreteGrey.withValues(alpha: 0.15))
                        : Colors.transparent),
                border: Border.all(
                  color: isToday
                      ? FormaColors.goldenYellow
                      : (hasLogs
                          ? const Color(0xFF659253)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : FormaColors.concreteGrey
                                  .withValues(alpha: 0.3))),
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Center(
                child: hasLogs
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : (isRest
                        ? Icon(
                            Icons.remove_rounded,
                            size: 12,
                            color: FormaColors.concreteGrey,
                          )
                        : null),
              ),
            ),
          ],
        );
      }),
    );
  }
}
