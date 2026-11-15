import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/expense_model.dart';

/// Pakee-inspired tactile Expense Card with Hero support for connected morph transitions.
class ExpenseCard extends StatelessWidget {
  final PersonalExpense expense;
  final VoidCallback? onTap;
  final String heroPrefix;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.heroPrefix = 'personal_exp',
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDay = DateTime(dt.year, dt.month, dt.day);

    if (expenseDay == today) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$min $period';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (expenseDay == yesterday) {
      return 'Yesterday';
    }

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
    final category = ExpenseCategory.fromName(expense.category);

    final cardBg = isDark ? FormaColors.charcoal : Colors.white;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;

    return FormaBounceable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Category Icon with Hero
            Hero(
              tag: '${heroPrefix}_icon_${expense.id}',
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: category.color.withValues(alpha: isDark ? 0.4 : 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title & Category / Date
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: category.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' • ${_formatDate(expense.date)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      expense.note!,
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryTextColor.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Large Financial Amount with Hero
            Hero(
              tag: '${heroPrefix}_amt_${expense.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  '${expense.currency}${expense.amount.toStringAsFixed(expense.amount.truncateToDouble() == expense.amount ? 0 : 2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
