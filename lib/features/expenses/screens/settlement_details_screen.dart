import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

/// Dedicated Settlement Details Screen between Current User and a Participant
class SettlementDetailsScreen extends ConsumerWidget {
  final ParticipantBalance balance;

  const SettlementDetailsScreen({super.key, required this.balance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;

    final user = ref.watch(currentFirebaseUserProvider);
    final myUid = user?.uid ?? '';

    final sharedAsync = ref.watch(sharedExpensesStreamProvider);
    final settlementsAsync = ref.watch(settlementsStreamProvider);

    final isOwed = balance.youAreOwed;
    final owes = balance.youOwe;

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
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: primaryTextColor, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
          'Settlement Ledger',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Participant Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : FormaColors.divider.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    FormaAvatar(
                      photoUrl: balance.photoUrl,
                      name: balance.displayName,
                      size: 72,
                      borderWidth: 2,
                      borderColor: FormaColors.goldenYellow,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      balance.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOwed
                            ? FormaColors.success.withValues(alpha: 0.18)
                            : (owes
                                ? FormaColors.coralPink.withValues(alpha: 0.18)
                                : FormaColors.concreteGrey
                                    .withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOwed
                            ? '${balance.displayName} owes you'
                            : (owes
                                ? 'You owe ${balance.displayName}'
                                : 'Fully Settled Up'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isOwed
                              ? FormaColors.success
                              : (owes
                                  ? FormaColors.coralPink
                                  : secondaryTextColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '₹${balance.netBalance.abs().toStringAsFixed(balance.netBalance.truncateToDouble() == balance.netBalance ? 0 : 2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: isOwed
                            ? FormaColors.success
                            : (owes ? FormaColors.coralPink : primaryTextColor),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Total recorded settled to date: ₹${balance.totalSettled.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Action: Record Settlement
              FormaBounceable(
                onTap: () => context.push(
                  '/shared-expenses/settle-up',
                  extra: balance,
                ),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow,
                    borderRadius: BorderRadius.circular(18),
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
                      const Icon(Icons.handshake_outlined,
                          color: FormaColors.charcoal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Record Settlement',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: FormaColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 3. Relevant Shared Expenses
              Text(
                'Expenses Involving ${balance.displayName}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),

              sharedAsync.when(
                data: (allShared) {
                  final relevant = allShared.where((exp) {
                    final hasMe =
                        exp.participants.any((p) => p.userId == myUid);
                    final hasThem = exp.participants
                        .any((p) => p.userId == balance.participantUid);
                    final isPayer = exp.paidByUid == myUid ||
                        exp.paidByUid == balance.participantUid;
                    return (hasMe && hasThem) || isPayer;
                  }).toList();

                  if (relevant.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No common shared expenses found.',
                          style: TextStyle(color: secondaryTextColor)),
                    );
                  }

                  return Column(
                    children: relevant.map((exp) {
                      final isPayer = exp.paidByUid == myUid;
                      final themShare =
                          exp.getShareForUser(balance.participantUid);
                      final myShare = exp.getShareForUser(myUid);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : FormaColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: primaryTextColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Paid by ${exp.paidByUid == myUid ? "You" : exp.paidByName}',
                                  style: TextStyle(
                                      fontSize: 12, color: secondaryTextColor),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${exp.totalAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: primaryTextColor),
                                ),
                                if (isPayer && themShare != null)
                                  Text(
                                    '${balance.displayName} owes ₹${themShare.assignedAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: FormaColors.success),
                                  )
                                else if (!isPayer && myShare != null)
                                  Text(
                                    'You owe ₹${myShare.assignedAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: FormaColors.coralPink),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 24),

              // 4. Relevant Recorded Settlements
              Text(
                'Settlement History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),

              settlementsAsync.when(
                data: (allSettlements) {
                  final relevant = allSettlements.where((s) {
                    return (s.payerUid == myUid &&
                            s.payeeUid == balance.participantUid) ||
                        (s.payerUid == balance.participantUid &&
                            s.payeeUid == myUid);
                  }).toList();

                  if (relevant.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No settlements recorded yet.',
                          style: TextStyle(color: secondaryTextColor)),
                    );
                  }

                  return Column(
                    children: relevant.map((s) {
                      final iPaid = s.payerUid == myUid;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : FormaColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  iPaid
                                      ? Icons.arrow_outward_rounded
                                      : Icons.call_received_rounded,
                                  color: iPaid
                                      ? FormaColors.coralPink
                                      : FormaColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      iPaid
                                          ? 'You paid ${s.payeeName}'
                                          : '${s.payerName} paid You',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: primaryTextColor),
                                    ),
                                    if (s.note != null && s.note!.isNotEmpty)
                                      Text(
                                        s.note!,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: secondaryTextColor),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              '₹${s.amount.toStringAsFixed(s.amount.truncateToDouble() == s.amount ? 0 : 2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: iPaid
                                    ? FormaColors.coralPink
                                    : FormaColors.success,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
