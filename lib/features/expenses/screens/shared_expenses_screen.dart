import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/components/shared_expense_card.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

/// Pakee-inspired Shared Expenses & Group Settlements Screen
class SharedExpensesScreen extends ConsumerStatefulWidget {
  const SharedExpensesScreen({super.key});

  @override
  ConsumerState<SharedExpensesScreen> createState() =>
      _SharedExpensesScreenState();
}

class _SharedExpensesScreenState extends ConsumerState<SharedExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;

    final user = ref.watch(currentFirebaseUserProvider);
    final uid = user?.uid ?? '';

    final sharedAsync = ref.watch(sharedExpensesStreamProvider);
    final balances = ref.watch(sharedBalancesProvider);

    // Compute aggregate overview
    double totalOwedToYou = 0.0;
    double totalYouOwe = 0.0;
    for (final b in balances) {
      if (b.youAreOwed) {
        totalOwedToYou += b.amountTheyOweYou;
      } else if (b.youOwe) {
        totalYouOwe += b.amountYouOweThem;
      }
    }
    final netOverall = totalOwedToYou - totalYouOwe;

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
          'Shared Expenses',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded,
                color: FormaColors.primaryAccent),
            tooltip: 'Personal Expenses',
            onPressed: () => context.push('/expenses'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: FormaColors.primaryAccent,
          onRefresh: () async {
            ref.invalidate(sharedExpensesStreamProvider);
            ref.invalidate(settlementsStreamProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Featured Summary Card (Oversized financial layout)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: FormaColors.charcoal,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
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
                              color: FormaColors.goldenYellow
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'NET SETTLEMENT BALANCE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: FormaColors.goldenYellow,
                              ),
                            ),
                          ),
                          Icon(
                            netOverall > 0
                                ? Icons.arrow_downward_rounded
                                : (netOverall < 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.check_circle_outline_rounded),
                            color: netOverall > 0
                                ? FormaColors.success
                                : (netOverall < 0
                                    ? FormaColors.coralPink
                                    : FormaColors.concreteGrey),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: netOverall >= 0
                                  ? FormaColors.success
                                  : FormaColors.coralPink,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            netOverall.abs().toStringAsFixed(
                                netOverall.truncateToDouble() == netOverall
                                    ? 0
                                    : 2),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        netOverall > 0.01
                            ? 'In total, you are owed this amount across group members.'
                            : (netOverall < -0.01
                                ? 'In total, you owe this amount across group members.'
                                : 'All shared balances are fully settled!'),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              FormaColors.concreteGrey.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YOU ARE OWED',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: FormaColors.concreteGrey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${totalOwedToYou.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: FormaColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              width: 1, height: 32, color: Colors.white12),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YOU OWE',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: FormaColors.concreteGrey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${totalYouOwe.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: FormaColors.coralPink,
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

                const SizedBox(height: 20),

                // 2. Main Actions: Add Shared Expense & Settle Up
                Row(
                  children: [
                    Expanded(
                      child: FormaBounceable(
                        onTap: () => context.push('/shared-expenses/add'),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: FormaColors.goldenYellow,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: FormaColors.goldenYellow
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: FormaColors.charcoal, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                'Add Expense',
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormaBounceable(
                        onTap: () => context.push('/shared-expenses/settle-up'),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  isDark ? Colors.white12 : FormaColors.divider,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.handshake_outlined,
                                  color: FormaColors.primaryAccent, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Settle Up',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 3. People & Balances Section
                if (balances.isNotEmpty) ...[
                  Text(
                    'People & Balances',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: balances.map((bal) {
                        final isOwed = bal.youAreOwed;
                        final owes = bal.youOwe;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: FormaBounceable(
                            onTap: () => context.push(
                              '/shared-expenses/settlements',
                              extra: bal,
                            ),
                            child: Container(
                              width: 160,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : FormaColors.divider
                                          .withValues(alpha: 0.6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: isDark ? 0.2 : 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FormaAvatar(
                                    photoUrl: bal.photoUrl,
                                    name: bal.displayName,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    bal.displayName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isOwed
                                        ? 'Owes you'
                                        : (owes ? 'You owe' : 'Settled up'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOwed
                                          ? FormaColors.success
                                          : (owes
                                              ? FormaColors.coralPink
                                              : secondaryTextColor),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${bal.netBalance.abs().toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isOwed
                                          ? FormaColors.success
                                          : (owes
                                              ? FormaColors.coralPink
                                              : primaryTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // 4. Recent Shared Expenses Section
                Text(
                  'Recent Shared Expenses',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),

                sharedAsync.when(
                  data: (sharedExpenses) {
                    if (sharedExpenses.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                isDark ? Colors.white10 : FormaColors.divider,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: FormaColors.primaryAccent
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.group_work_rounded,
                                size: 36,
                                color: FormaColors.primaryAccent,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No Shared Expenses Yet',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Easily split group meals, cab rides, and fitness events with friends.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: sharedExpenses.take(8).map((exp) {
                        return SharedExpenseCard(
                          expense: exp,
                          currentUserUid: uid,
                          onTap: () => context.push(
                            '/shared-expenses/detail',
                            extra: exp,
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: FormaColors.primaryAccent)),
                  error: (err, _) => Text('Error: $err'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
