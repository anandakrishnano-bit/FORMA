import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

/// Shared-element Detail Screen for a Shared Expense
class SharedExpenseDetailScreen extends ConsumerWidget {
  final SharedExpense expense;
  final String heroPrefix;

  const SharedExpenseDetailScreen({
    super.key,
    required this.expense,
    this.heroPrefix = 'shared_exp',
  });

  String _formatDate(DateTime dt) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _deleteSharedExpense(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? FormaColors.charcoal
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Shared Expense',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to delete this shared expense? Balances for all participants will be recalculated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FormaColors.coralPink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(expenseRepositoryProvider).deleteSharedExpense(expense.id);
      HapticFeedback.mediumImpact();
      if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;

    final user = ref.watch(currentFirebaseUserProvider);
    final isCreator = expense.createdBy == user?.uid;

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
          'Shared Expense Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        actions: [
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: FormaColors.coralPink),
              tooltip: 'Delete',
              onPressed: () => _deleteSharedExpense(context, ref),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Featured Card with Hero
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
                    Hero(
                      tag: '${heroPrefix}_title_${expense.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          expense.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Paid by ${expense.paidByName} on ${_formatDate(expense.date)}',
                      style: TextStyle(fontSize: 13, color: secondaryTextColor),
                    ),
                    const SizedBox(height: 18),
                    Hero(
                      tag: '${heroPrefix}_total_${expense.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          '${expense.currency}${expense.totalAmount.toStringAsFixed(expense.totalAmount.truncateToDouble() == expense.totalAmount ? 0 : 2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            FormaColors.primaryAccent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Split Method: ${expense.splitMethod.name.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: FormaColors.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Note Section
              if (expense.note != null && expense.note!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark ? Colors.white10 : FormaColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note_rounded,
                          size: 20, color: FormaColors.primaryAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          expense.note!,
                          style:
                              TextStyle(fontSize: 14, color: primaryTextColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 3. Participant Shares Breakdown
              Text(
                'Participant Shares (${expense.participants.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : FormaColors.divider.withValues(alpha: 0.6)),
                ),
                child: Column(
                  children: expense.participants.map((p) {
                    final isUserPayer = p.userId == expense.paidByUid;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          FormaAvatar(
                            photoUrl: p.photoUrl,
                            name: p.displayName,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.displayName,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor),
                                ),
                                if (isUserPayer)
                                  const Text(
                                    'Paid full amount',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: FormaColors.success,
                                        fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${p.assignedAmount.toStringAsFixed(p.assignedAmount.truncateToDouble() == p.assignedAmount ? 0 : 2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: primaryTextColor,
                                ),
                              ),
                              if (p.percentage != null)
                                Text(
                                  '${p.percentage!.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      fontSize: 11, color: secondaryTextColor),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Settle Up Shortcut
              FormaBounceable(
                onTap: () => context.push('/shared-expenses/settle-up'),
                child: Container(
                  width: double.infinity,
                  height: 52,
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
                        'Record a Settlement',
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
            ],
          ),
        ),
      ),
    );
  }
}
