import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/repositories/expense_repository.dart';

/// Smart Spending Insights & Analytics for FORMA.
///
/// Features:
/// - Weekly & Monthly Totals and Burn Rate
/// - Spending Trends across 7 days
/// - Category distribution breakdown with visual bars and percentage shares
/// - Recurring habits expenditure tracking (Eggs, Groceries, Transit, Protein)
/// - Deterministic pattern detection (adherence rate, peak spending day, savings variance)
/// - ZERO FAKE DATA GUARANTEE: Uses only genuine authenticated user transactions.
class SpendingInsightsScreen extends ConsumerStatefulWidget {
  const SpendingInsightsScreen({super.key});

  @override
  ConsumerState<SpendingInsightsScreen> createState() =>
      _SpendingInsightsScreenState();
}

class _SpendingInsightsScreenState
    extends ConsumerState<SpendingInsightsScreen> {
  int _selectedPeriod = 0; // 0 = Last 7 Days, 1 = Last 30 Days

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final expensesAsync = ref.watch(personalExpensesStreamProvider);
    final fixedAsync = ref.watch(fixedExpensesProvider);
    final summary = ref.watch(budgetPlannerSummaryProvider);

    final allExpenses = expensesAsync.valueOrNull ?? [];
    final fixedHabits =
        (fixedAsync.valueOrNull ?? []).where((f) => !f.isObligation).toList();

    final now = DateTime.now();
    final daysToLookBack = _selectedPeriod == 0 ? 7 : 30;
    final startDate = now.subtract(Duration(days: daysToLookBack - 1));
    final periodExpenses = allExpenses.where((e) {
      return e.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    final totalSpent = periodExpenses.fold(0.0, (acc, e) => acc + e.amount);
    final avgDailyBurn = totalSpent / daysToLookBack;

    // Category breakdown
    final Map<String, double> categoryTotals = {};
    for (final exp in periodExpenses) {
      categoryTotals[exp.category] =
          (categoryTotals[exp.category] ?? 0.0) + exp.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Daily breakdown for trend bar chart
    final List<({DateTime date, double total})> dailyData = [];
    for (int i = daysToLookBack - 1; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayTotal = periodExpenses
          .where((e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day)
          .fold(0.0, (acc, e) => acc + e.amount);
      dailyData.add((date: day, total: dayTotal));
    }

    final maxDaySpend =
        dailyData.fold(0.0, (m, d) => d.total > m ? d.total : m);

    // Recurring Habits Tracking
    final List<({String habitName, double targetGuide, double actualSpent})>
        habitTracking = [];
    for (final habit in fixedHabits) {
      // Find actual expenses matching this habit title or note
      final actualMatches = periodExpenses.where((e) {
        return e.title.toLowerCase().contains(habit.name.toLowerCase()) ||
            (e.note?.toLowerCase().contains(habit.name.toLowerCase()) ?? false);
      });
      final actualSum = actualMatches.fold(0.0, (acc, e) => acc + e.amount);
      final daysScale = daysToLookBack / 30.0;
      habitTracking.add((
        habitName: habit.name,
        targetGuide: habit.amount * daysScale,
        actualSpent: actualSum,
      ));
    }

    // Pattern Detection
    final nonZeroDays = dailyData.where((d) => d.total > 0).toList();
    final peakDay = nonZeroDays.isNotEmpty
        ? (List.from(nonZeroDays)..sort((a, b) => b.total.compareTo(a.total)))
            .first
        : null;

    final allowance = summary.suggestedDailyAllowance;
    final underBudgetDays =
        allowance > 0 ? dailyData.where((d) => d.total <= allowance).length : 0;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Spending Insights',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      isDark ? FormaColors.charcoal : const Color(0xFFF0EDE5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPeriodButton(
                        label: 'Last 7 Days',
                        isSelected: _selectedPeriod == 0,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedPeriod = 0);
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildPeriodButton(
                        label: 'Last 30 Days',
                        isSelected: _selectedPeriod == 1,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedPeriod = 1);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Overview Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SPENT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: FormaColors.concreteGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${totalSpent.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: isDark
                                ? FormaColors.darkPrimaryText
                                : FormaColors.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${periodExpenses.length} transactions)',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: isDark ? Colors.white10 : Colors.black12),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatColumn(
                          label: 'Daily Burn Rate',
                          value: '₹${avgDailyBurn.toStringAsFixed(0)}/day',
                          isDark: isDark,
                        ),
                        if (allowance > 0)
                          _buildStatColumn(
                            label: 'Daily Allowance',
                            value: '₹${allowance.toStringAsFixed(0)}/day',
                            isDark: isDark,
                          ),
                        _buildStatColumn(
                          label: 'Adherence',
                          value: allowance > 0
                              ? '$underBudgetDays/$daysToLookBack days'
                              : 'N/A',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Spending Trends Chart
              Text(
                'Spending Trend',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 170,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : FormaColors.divider.withValues(alpha: 0.6),
                  ),
                ),
                child: maxDaySpend == 0
                    ? Center(
                        child: Text(
                          'No spending recorded for this timeframe.',
                          style: TextStyle(
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: dailyData.take(14).map((d) {
                          final heightPct = maxDaySpend > 0
                              ? (d.total / maxDaySpend).clamp(0.06, 1.0)
                              : 0.06;
                          final isOver = allowance > 0 && d.total > allowance;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (d.total > 0)
                                    Text(
                                      '₹${d.total.toInt()}',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: isOver
                                            ? FormaColors.coralPink
                                            : FormaColors.goldenYellow,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: (heightPct * 90).toDouble(),
                                    decoration: BoxDecoration(
                                      color: isOver
                                          ? FormaColors.coralPink
                                          : (d.total > 0
                                              ? FormaColors.goldenYellow
                                              : (isDark
                                                  ? Colors.white10
                                                  : Colors.black12)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('E')
                                        .format(d.date)
                                        .substring(0, 1),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? FormaColors.darkSecondaryText
                                          : FormaColors.lightSecondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 24),

              // Category Breakdown
              Text(
                'Spending by Category',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 10),
              Container(
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
                child: sortedCategories.isEmpty
                    ? Center(
                        child: Text(
                          'No categories recorded yet.',
                          style: TextStyle(
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                          ),
                        ),
                      )
                    : Column(
                        children: sortedCategories.map((entry) {
                          final pct =
                              totalSpent > 0 ? (entry.value / totalSpent) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      '₹${entry.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: isDark
                                            ? FormaColors.goldenYellow
                                            : FormaColors.charcoal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 6,
                                    backgroundColor: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                    valueColor: const AlwaysStoppedAnimation(
                                        FormaColors.goldenYellow),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 24),

              // Recurring Habits Tracker
              if (habitTracking.isNotEmpty) ...[
                Text(
                  'Recurring Habits Tracking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Compares actual purchases matching your configured recurring habits against spending targets.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
                const SizedBox(height: 10),
                ...habitTracking.map((h) {
                  final variance = h.actualSpent - h.targetGuide;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? FormaColors.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : FormaColors.divider.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: FormaColors.secondaryAccent
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.repeat_rounded,
                              size: 18, color: FormaColors.secondaryAccent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.habitName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              Text(
                                'Actual: ₹${h.actualSpent.toStringAsFixed(0)} • Guide: ₹${h.targetGuide.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (variance <= 0
                                    ? FormaColors.semanticSteps
                                    : FormaColors.coralPink)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            variance <= 0
                                ? 'On Track'
                                : '+₹${variance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: variance <= 0
                                  ? FormaColors.semanticSteps
                                  : FormaColors.coralPink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Pattern Detection Summary
              if (peakDay != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: FormaColors.goldenYellow.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          color: FormaColors.goldenYellow, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Spending Pattern Detected',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Peak spending occurred on ${DateFormat('EEEE, d MMM').format(peakDay.date)} (₹${peakDay.total.toStringAsFixed(0)}).',
                              style: TextStyle(
                                fontSize: 12,
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
                ),
              ],

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FormaColors.goldenYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? FormaColors.charcoal
                  : (isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }
}
