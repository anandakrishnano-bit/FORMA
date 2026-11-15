import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:forma/core/components/expense_card.dart';
import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/services/biometric_auth_service.dart';
import 'package:forma/core/services/forma_haptics.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';
import 'package:forma/features/expenses/screens/fixed_expenses_screen.dart';
import 'package:forma/features/expenses/screens/plan_budget_modal.dart';

/// Rebuilt Personal Budget Planner & Spending Dashboard (Tab 5)
///
/// Features:
/// - Profile Avatar shortcut in header (Part 2.1)
/// - Large featured budget card with oversized currency typography (Part 1.8)
/// - Today's Budget allowance & actual spending tracker (Part 1.4)
/// - Cumulative spending & carryover (Part 1.5)
/// - Flexible spending strategies toggle: Daily Plan vs Cumulative Plan (Part 1.6)
/// - Dedicated Fixed Commitments section with reserved amounts (Part 1.2)
/// - Traceable, grounded budget suggestions (Part 1.7)
/// - Variable spending history with connected Hero morph transitions
class PersonalExpensesScreen extends ConsumerStatefulWidget {
  const PersonalExpensesScreen({super.key});

  @override
  ConsumerState<PersonalExpensesScreen> createState() =>
      _PersonalExpensesScreenState();
}

class _PersonalExpensesScreenState
    extends ConsumerState<PersonalExpensesScreen> {
  // Strategy: false = Daily Plan, true = Flexible / Cumulative Plan
  bool _isFlexibleMode = false;
  bool _isLocked = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricLock();
  }

  Future<void> _checkBiometricLock() async {
    final lockEnabled = await BiometricAuthService().isExpensesLockEnabled();
    if (!lockEnabled) {
      if (mounted) setState(() => _isCheckingAuth = false);
      return;
    }

    final authenticated = await BiometricAuthService().authenticate(
      reason: 'Confirm your biometric identity to access private expenses',
    );

    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
        _isLocked = !authenticated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        body: const Center(
          child: CircularProgressIndicator(color: FormaColors.primaryAccent),
        ),
      );
    }

    if (_isLocked) {
      return Scaffold(
        backgroundColor:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: isDark ? Colors.white : FormaColors.charcoal),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: FormaColors.primaryAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      size: 54, color: FormaColors.primaryAccent),
                ),
                const SizedBox(height: 24),
                Text(
                  'Expenses Locked',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your personal spending records are protected by biometric app lock.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () {
                    FormaHaptics.lightImpact();
                    setState(() => _isCheckingAuth = true);
                    _checkBiometricLock();
                  },
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Unlock with Biometrics',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FormaColors.primaryAccent,
                    foregroundColor: FormaColors.charcoal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final user = FirebaseAuth.instance.currentUser;
    final userProfileAsync = ref.watch(currentUserProfileStreamProvider);
    final userProfile = userProfileAsync.valueOrNull;

    final summary = ref.watch(budgetPlannerSummaryProvider);
    final expensesAsync = ref.watch(personalExpensesStreamProvider);

    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;

    final userName = userProfile?.displayName ?? user?.displayName ?? 'Athlete';
    final userPhotoUrl = userProfile?.photoUrl ??
        userProfile?.photoURL ??
        userProfile?.avatarUrl ??
        user?.photoURL;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: FormaColors.primaryAccent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 18,
                color: FormaColors.charcoal,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Expenses',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
              ),
            ),
          ],
        ),
        actions: [
          // Shared Expenses shortcut
          IconButton(
            icon: const Icon(
              Icons.people_outline_rounded,
              color: FormaColors.semanticWorkout,
            ),
            tooltip: 'Shared Expenses & Ledger',
            onPressed: () => context.push('/shared-expenses'),
          ),
          // History shortcut
          IconButton(
            icon: Icon(Icons.history_rounded, color: primaryTextColor),
            tooltip: 'Expense History',
            onPressed: () => context.push('/expenses/history'),
          ),
          // Spending Insights shortcut
          IconButton(
            icon: const Icon(Icons.insights_rounded,
                color: FormaColors.goldenYellow),
            tooltip: 'Spending Insights',
            onPressed: () => context.push('/expenses/insights'),
          ),
          const SizedBox(width: 4),

          // ── PART 2.1: PROFILE AVATAR BUTTON IN EXPENSES HEADER ──
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/profile');
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FormaAvatar(
                photoUrl: userPhotoUrl,
                name: userName,
                size: 38,
                borderWidth: 2,
                borderColor: FormaColors.goldenYellow,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.only(left: 20, right: 20, bottom: 120, top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. FEATURED BUDGET PLANNER CARD
              if (summary.plan != null) ...[
                _buildFeaturedBudgetCard(context, summary, isDark),
              ] else ...[
                _buildNoBudgetCard(context, isDark),
              ],
              const SizedBox(height: 20),

              // 2. TODAY'S SPENDING PLANNER (Part 1.4)
              if (summary.plan != null) ...[
                _buildTodayBudgetSection(context, summary, isDark),
                const SizedBox(height: 20),
              ],

              // 3. FIXED COMMITMENTS PREVIEW (Part 1.2)
              _buildFixedCommitmentsCard(context, summary, isDark),
              const SizedBox(height: 20),

              // 4. TRACEABLE BUDGET SUGGESTIONS (Part 1.7)
              if (summary.suggestions.isNotEmpty) ...[
                _buildSuggestionsCarousel(summary, isDark),
                const SizedBox(height: 24),
              ],

              // 5. RECENT SPENDING TRANSACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Expenses',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/expenses/history'),
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FormaColors.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              expensesAsync.when(
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? FormaColors.charcoal : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : FormaColors.concreteGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            size: 36,
                            color: FormaColors.concreteGrey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Expenses Recorded Yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color:
                                  isDark ? Colors.white : FormaColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "Add Expense" below to log variable daily spending with the custom tactile keypad.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final recent = expenses.take(5).toList();
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = recent[index];
                      return ExpenseCard(
                        expense: item,
                        onTap: () =>
                            context.push('/expenses/detail', extra: item),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading expenses: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedBudgetCard(
    BuildContext context,
    BudgetPlannerSummary summary,
    bool isDark,
  ) {
    final plan = summary.plan!;
    final remaining = summary.remainingSpendableBudget;
    final total = summary.totalBudget;
    final currency = plan.currency;

    final progressFraction =
        total > 0 ? ((total - remaining) / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: summary.isOverBudget
              ? FormaColors.coralPink.withValues(alpha: 0.5)
              : (isDark
                  ? Colors.white10
                  : FormaColors.concreteGrey.withValues(alpha: 0.2)),
          width: summary.isOverBudget ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REMAINING BUDGET',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: summary.isOverBudget
                            ? FormaColors.coralPink
                            : FormaColors.concreteGrey,
                      ),
                    ),
                    if (plan.description != null &&
                        plan.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          plan.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, size: 22),
                tooltip: 'Edit Budget Plan',
                onPressed: () =>
                    showPlanBudgetModal(context, existingPlan: plan),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Oversized Balance Typography (Part 1.8) - Scaled with FittedBox to prevent overflow
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currency,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: summary.isOverBudget
                              ? FormaColors.coralPink
                              : (isDark ? Colors.white : FormaColors.charcoal),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        NumberFormat('#,##,###')
                            .format(remaining.abs().toInt()),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          color: summary.isOverBudget
                              ? FormaColors.coralPink
                              : (isDark ? Colors.white : FormaColors.charcoal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FormaColors.primaryAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${summary.daysRemaining} days left',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: FormaColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual Progress Capsule
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : FormaColors.concreteGrey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.isOverBudget
                    ? FormaColors.coralPink
                    : FormaColors.primaryAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metadata breakdown row - Distributed across Expanded columns
          Row(
            children: [
              Expanded(
                child: _buildMiniBudgetStat(
                  label: 'Allocated',
                  value: '$currency${total.toStringAsFixed(0)}',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildMiniBudgetStat(
                  label: 'Spent',
                  value: '$currency${summary.variableSpent.toStringAsFixed(0)}',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildMiniBudgetStat(
                  label: 'Reserved',
                  value:
                      '$currency${summary.upcomingFixedReserved.toStringAsFixed(0)}',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildMiniBudgetStat(
                  label: 'Daily Avg',
                  value:
                      '$currency${summary.suggestedDailyAllowance.toStringAsFixed(0)}',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (summary.expectedDailyHabitsAllocation > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: FormaColors.icyBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat_rounded,
                      size: 14, color: FormaColors.charcoal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Includes ~₹${summary.expectedDailyHabitsAllocation.toStringAsFixed(0)}/day for recurring spending habits',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniBudgetStat({
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
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : FormaColors.charcoal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoBudgetCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : FormaColors.concreteGrey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FormaColors.primaryAccent.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: FormaColors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Active Budget Period',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? Colors.white : FormaColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Allocate money for a period to get an intelligent daily spending allowance.',
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
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => showPlanBudgetModal(context),
            icon: const Icon(Icons.add_task_rounded, size: 18),
            label: const Text('Plan My Budget',
                style: TextStyle(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: FormaColors.primaryAccent,
              foregroundColor: FormaColors.charcoal,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayBudgetSection(
    BuildContext context,
    BudgetPlannerSummary summary,
    bool isDark,
  ) {
    final currency = summary.plan?.currency ?? '₹';
    final suggested = summary.suggestedDailyAllowance;
    final todaySpent = summary.todayActualSpent;
    final remainingToday = summary.todayRemainingAllowance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white10
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
                "Today's Spending Plan",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isDark ? Colors.white : FormaColors.charcoal,
                ),
              ),
              // Strategy switch pill (Part 1.6)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isFlexibleMode = !_isFlexibleMode);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FormaColors.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFlexibleMode
                            ? Icons.all_inclusive_rounded
                            : Icons.today_rounded,
                        size: 13,
                        color: FormaColors.charcoal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isFlexibleMode ? 'Flexible Plan' : 'Daily Plan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: FormaColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!_isFlexibleMode) ...[
            // Daily Plan View (Part 1.4)
            Row(
              children: [
                Expanded(
                  child: _buildPlannerCard(
                    title: 'Suggested Today',
                    value: '$currency${suggested.toStringAsFixed(0)}',
                    color: FormaColors.goldenYellow,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPlannerCard(
                    title: 'Spent Today',
                    value: '$currency${todaySpent.toStringAsFixed(0)}',
                    color: isDark ? Colors.white : FormaColors.charcoal,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPlannerCard(
                    title: 'Remaining Today',
                    value:
                        '$currency${remainingToday > 0 ? remainingToday.toStringAsFixed(0) : '0'}',
                    color: remainingToday < 0
                        ? FormaColors.coralPink
                        : FormaColors.semanticSuccess,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Flexible / Cumulative Plan View (Part 1.6)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FormaColors.icyBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Flexible Cumulative Strategy',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$currency${summary.remainingSpendableBudget.toStringAsFixed(0)} Total Left',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: FormaColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Allows variable daily spending. Any unspent balance automatically increases future allowances across the remaining ${summary.daysRemaining} days.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlannerCard({
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFixedCommitmentsCard(
    BuildContext context,
    BudgetPlannerSummary summary,
    bool isDark,
  ) {
    final currency = summary.plan?.currency ?? '₹';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FixedExpensesScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? FormaColors.charcoal : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : FormaColors.concreteGrey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FormaColors.coralPink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: FormaColors.coralPink,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fixed Expenses & Commitments',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark ? Colors.white : FormaColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.upcomingFixedReserved > 0
                        ? '$currency${summary.upcomingFixedReserved.toStringAsFixed(0)} reserved for upcoming payments'
                        : 'Manage rent, passes, subscriptions and recurring costs',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: FormaColors.concreteGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCarousel(
    BudgetPlannerSummary summary,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insights_rounded,
                size: 16, color: FormaColors.primaryAccent),
            const SizedBox(width: 6),
            Text(
              'Budget Insights',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isDark ? Colors.white70 : FormaColors.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: summary.suggestions.map((text) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.charcoal.withValues(alpha: 0.6)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : FormaColors.concreteGrey.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
