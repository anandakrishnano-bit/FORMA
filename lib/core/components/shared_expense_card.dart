import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/expense_model.dart';

/// Pakee-inspired Shared Expense Card
class SharedExpenseCard extends StatelessWidget {
  final SharedExpense expense;
  final String currentUserUid;
  final VoidCallback? onTap;
  final String heroPrefix;

  const SharedExpenseCard({
    super.key,
    required this.expense,
    required this.currentUserUid,
    this.onTap,
    this.heroPrefix = 'shared_exp',
  });

  String _formatDate(DateTime dt) {
    final months = [
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
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;

    final isPayer = expense.paidByUid == currentUserUid;
    final myShare = expense.getShareForUser(currentUserUid);

    return FormaBounceable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : FormaColors.divider.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title, Date, Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: '${heroPrefix}_title_${expense.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            expense.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Paid by ${isPayer ? "You" : expense.paidByName} • ${_formatDate(expense.date)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Hero(
                  tag: '${heroPrefix}_total_${expense.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      '${expense.currency}${expense.totalAmount.toStringAsFixed(expense.totalAmount.truncateToDouble() == expense.totalAmount ? 0 : 2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (expense.note != null && expense.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                expense.note!,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: secondaryTextColor.withValues(alpha: 0.85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8),
            const SizedBox(height: 10),

            // Bottom Row: Personal share or obligation indicator & participant pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Participant count
                Row(
                  children: [
                    Icon(Icons.group_outlined,
                        size: 16, color: secondaryTextColor),
                    const SizedBox(width: 6),
                    Text(
                      '${expense.participants.length} people (${expense.splitMethod.name})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),

                // Share / Owed status
                if (isPayer)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FormaColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'You paid ${expense.currency}${expense.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FormaColors.success,
                      ),
                    ),
                  )
                else if (myShare != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FormaColors.coralPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Your share: ${expense.currency}${myShare.assignedAmount.toStringAsFixed(myShare.assignedAmount.truncateToDouble() == myShare.assignedAmount ? 0 : 2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FormaColors.coralPink,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
