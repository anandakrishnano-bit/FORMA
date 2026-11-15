import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/muscle_tracker_model.dart';
import 'package:forma/data/repositories/daily_summary_repository.dart';
import 'package:forma/data/repositories/hydration_repository.dart';
import 'package:forma/data/repositories/muscle_tracker_repository.dart';
import 'package:forma/features/body/widgets/anatomical_body_widget.dart';

/// Body & Activity Visualization Screen
///
/// Strictly genuine recorded activity, verified anatomical mapping,
/// and truthful metrics without fabricated fat-loss or body water percentages.
class BodyActivityScreen extends ConsumerStatefulWidget {
  const BodyActivityScreen({super.key});

  @override
  ConsumerState<BodyActivityScreen> createState() => _BodyActivityScreenState();
}

class _BodyActivityScreenState extends ConsumerState<BodyActivityScreen> {
  MajorMuscleGroup? _selectedMuscle;

  void _showMuscleDetailsSheet(BuildContext context, MajorMuscleGroup muscle,
      List<MuscleTrainingLog> logs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;

    // Filter logs that trained this muscle
    final relevantLogs = logs.where((l) {
      return l.muscleGroups.any(
        (m) =>
            m.toLowerCase() == muscle.name.toLowerCase() ||
            m.toLowerCase() == muscle.id,
      );
    }).toList();

    DateTime? lastTrained;
    if (relevantLogs.isNotEmpty) {
      lastTrained = relevantLogs.first.workoutDate;
    }

    final contributingExercises =
        relevantLogs.expand((l) => l.contributingExercises).toSet().toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: muscle.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(muscle.icon, color: muscle.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        muscle.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        relevantLogs.isNotEmpty
                            ? 'Trained ${relevantLogs.length} time${relevantLogs.length == 1 ? "" : "s"} this week'
                            : 'Not trained this week',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: relevantLogs.isNotEmpty
                              ? FormaColors.success
                              : secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              muscle.description,
              style: TextStyle(
                  fontSize: 13, color: secondaryTextColor, height: 1.4),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Last Trained Date',
              lastTrained != null
                  ? '${lastTrained.day}/${lastTrained.month}/${lastTrained.year}'
                  : 'No recent workout logged in FORMA',
              primaryTextColor,
              secondaryTextColor,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              'Training Frequency',
              '${relevantLogs.length} session${relevantLogs.length == 1 ? "" : "s"} recorded this week',
              primaryTextColor,
              secondaryTextColor,
            ),
            if (contributingExercises.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recorded Exercises',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: contributingExercises.map((e) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: FormaColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: FormaColors.primaryAccent),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, Color textColor, Color secondaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: secondaryColor)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;

    final weekLogsAsync = ref.watch(currentWeekMuscleLogsProvider);
    final weekPlanAsync = ref.watch(currentWeeklyPlanProvider);
    final todaySummaryAsync = ref.watch(todaySummaryProvider);
    final hydrationMl = ref.watch(dailyHydrationProvider);

    final logs = weekLogsAsync.valueOrNull ?? [];
    final plan = weekPlanAsync.valueOrNull;

    final trainedSet = logs.expand((l) => l.muscleGroups).toSet();
    final plannedSet = plan?.allWeeklyPlannedMuscles ?? {};

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryTextColor, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Body & Activity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Body Settings',
            onPressed: () => context.push('/profile/body-settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Anatomical Body Illustration
              AnatomicalBodyWidget(
                trainedMuscles: trainedSet,
                plannedMuscles: plannedSet,
                selectedMuscle: _selectedMuscle,
                onMuscleSelected: (muscle) {
                  setState(() => _selectedMuscle = muscle);
                  _showMuscleDetailsSheet(context, muscle, logs);
                },
              ),

              const SizedBox(height: 24),

              // 2. Genuine Daily Activity Section
              Text(
                'Today’s Recorded Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),

              todaySummaryAsync.when(
                data: (summary) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.directions_walk_rounded,
                              iconColor: FormaColors.goldenYellow,
                              label: 'Steps',
                              value: '${summary.steps}',
                              sublabel: 'Pedometer sensor',
                              cardBg: cardBg,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: FormaColors.coralPink,
                              label: 'Active Energy',
                              value: '${summary.activeCalories.toInt()} kcal',
                              sublabel: 'Calculated work',
                              cardBg: cardBg,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.fitness_center_rounded,
                              iconColor: FormaColors.terracotta,
                              label: 'Workouts',
                              value: '${logs.length}',
                              sublabel: 'Sessions logged',
                              cardBg: cardBg,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.water_drop_rounded,
                              iconColor: FormaColors.azure,
                              label: 'Hydration',
                              value: '$hydrationMl ml',
                              sublabel: 'Logged intake',
                              cardBg: cardBg,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // 3. Hydration Log Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    FormaColors.azure.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.water_drop_rounded,
                                  color: FormaColors.azure, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Hydration Tracking',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$hydrationMl / 3000 ml',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: FormaColors.azure,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (hydrationMl / 3000.0).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor:
                            isDark ? Colors.white10 : const Color(0xFFE8EEF5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            FormaColors.azure),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tracks your recorded water consumed throughout the day. No continuous body-water percentage is fabricated.',
                      style: TextStyle(
                          fontSize: 12, color: secondaryTextColor, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick action: Open Weekly Muscle Planner
              FormaBounceable(
                onTap: () => context.push('/workout/muscle-overview'),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: FormaColors.goldenYellow.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_view_week_rounded,
                          color: FormaColors.charcoal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Open Weekly Muscle Planner',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: FormaColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sublabel,
    required Color cardBg,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
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
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(
                fontSize: 10, color: isDark ? Colors.white38 : Colors.grey),
          ),
        ],
      ),
    );
  }
}
