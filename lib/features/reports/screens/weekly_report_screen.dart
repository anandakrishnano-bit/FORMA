import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/repositories/daily_summary_repository.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:forma/features/reports/models/weekly_report_model.dart';
import 'package:forma/features/reports/repositories/weekly_report_repository.dart';

/// "Your Week in FORMA" Weekly Intelligence Report Screen.
class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  bool _isRefreshing = false;

  Future<void> _regenerateReport() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);

    try {
      final workouts = await ref.read(workoutHistoryProvider.future);
      final summaries =
          ref.read(recentDailySummariesProvider).valueOrNull ?? [];
      final expenses =
          ref.read(personalExpensesStreamProvider).valueOrNull ?? [];
      final budgetSummary = ref.read(budgetPlannerSummaryProvider);

      await ref.read(weeklyReportRepositoryProvider).generateWeeklyReport(
            workouts: workouts,
            summaries: summaries,
            expenses: expenses,
            budgetSummary: budgetSummary,
            forceAiRefresh: true,
          );

      ref.invalidate(currentWeeklyReportProvider);
    } catch (_) {}

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _shareReport(WeeklyReport report) {
    final range =
        '${DateFormat('d MMM').format(report.startDate)} - ${DateFormat('d MMM yyyy').format(report.endDate)}';
    final shareText = '''
FORMA Weekly Intelligence Report ($range)
• Workouts: ${report.totalWorkouts} sessions (${report.totalVolumeKg.toInt()} kg volume)
• Steps: ${report.totalSteps} (avg ${report.avgDailySteps}/day)
• Habits Consistency: ${report.habitConsistencyRate.toInt()}%
• Spending: ₹${report.totalSpent.toStringAsFixed(0)} (${report.daysWithinBudget}/7 days under budget)

${report.coachSynthesis}

Tracked with FORMA.
''';
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportAsync = ref.watch(currentWeeklyReportProvider);

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Your Week in FORMA',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          reportAsync.when(
            data: (report) => IconButton(
              icon: const Icon(Icons.share_rounded, size: 20),
              onPressed: () => _shareReport(report),
              tooltip: 'Share Report',
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: reportAsync.when(
          data: (report) => _buildReportContent(report, isDark),
          loading: () => const Center(
            child: CircularProgressIndicator(color: FormaColors.goldenYellow),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: FormaColors.coralPink),
                  const SizedBox(height: 12),
                  Text(
                    'Could not generate report',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(currentWeeklyReportProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(WeeklyReport report, bool isDark) {
    final rangeStr =
        '${DateFormat('d MMMM').format(report.startDate)} – ${DateFormat('d MMMM yyyy').format(report.endDate)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: FormaColors.goldenYellow.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              rangeStr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: FormaColors.goldenYellow,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Main Title
          Text(
            'Performance Summary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 16),

          // Bento Metric Grid (2x2)
          Row(
            children: [
              Expanded(
                child: _buildBentoCard(
                  title: 'TRAINING',
                  value: '${report.totalWorkouts}',
                  unit: 'sessions',
                  sub:
                      '${(report.totalVolumeKg / 1000).toStringAsFixed(1)}t volume',
                  color: FormaColors.coralPink,
                  icon: Icons.fitness_center_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoCard(
                  title: 'STEPS',
                  value: '${report.totalSteps}',
                  unit: 'total',
                  sub: 'avg ${report.avgDailySteps}/day',
                  color: FormaColors.semanticSteps,
                  icon: Icons.directions_walk_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBentoCard(
                  title: 'HABITS',
                  value: '${report.habitConsistencyRate.toInt()}%',
                  unit: 'consistency',
                  sub: '${report.totalHabitsCompleted} completed',
                  color: FormaColors.secondaryAccent,
                  icon: Icons.check_circle_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoCard(
                  title: 'EXPENSES',
                  value: '₹${report.totalSpent.toStringAsFixed(0)}',
                  unit: 'spent',
                  sub: '${report.daysWithinBudget}/7d on budget',
                  color: isDark ? Colors.white70 : FormaColors.charcoal,
                  icon: Icons.account_balance_wallet_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Coach Reflection & Synthesis Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? FormaColors.charcoal : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: FormaColors.goldenYellow.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 14,
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: FormaColors.goldenYellow
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded,
                              color: FormaColors.goldenYellow, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'COACH SYNTHESIS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: FormaColors.goldenYellow,
                          ),
                        ),
                      ],
                    ),
                    if (report.isAiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              FormaColors.goldenYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Gemini 1.5',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: FormaColors.goldenYellow,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  report.coachSynthesis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Highlights
          Text(
            'Weekly Highlights',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 10),
          ...report.highlights.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: FormaColors.goldenYellow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        h,
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
              )),

          const SizedBox(height: 28),

          // Regenerate Button
          Center(
            child: FormaBounceable(
              onTap: _isRefreshing ? null : _regenerateReport,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRefreshing) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: FormaColors.goldenYellow),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      const Icon(Icons.refresh_rounded, size: 18),
                      const SizedBox(width: 8),
                    ],
                    const Text(
                      'Regenerate Synthesis',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String value,
    required String unit,
    required String sub,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: color,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
