import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/repositories/expense_repository.dart';

/// Connected Shared-Element Detail Screen for a Personal Expense
class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final PersonalExpense expense;
  final String heroPrefix;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    this.heroPrefix = 'personal_exp',
  });

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  late PersonalExpense _currentExpense;

  @override
  void initState() {
    super.initState();
    _currentExpense = widget.expense;
  }

  String _formatFullDate(DateTime dt) {
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
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$min $period';
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? FormaColors.charcoal
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Expense',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
            'Are you sure you want to permanently delete this expense? This action cannot be undone.'),
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
      await ref
          .read(expenseRepositoryProvider)
          .deletePersonalExpense(_currentExpense.id);
      HapticFeedback.mediumImpact();
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;

    final category = ExpenseCategory.fromName(_currentExpense.category);

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
          'Expense Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Expense',
            onPressed: () async {
              await context.push('/expenses/add', extra: _currentExpense);
              // Refetch or pop
              if (mounted) context.pop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: FormaColors.coralPink),
            tooltip: 'Delete Expense',
            onPressed: _deleteExpense,
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
              // 1. Featured Header Card with Connected Hero
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
                      tag: '${widget.heroPrefix}_icon_${_currentExpense.id}',
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: category.color
                              .withValues(alpha: isDark ? 0.25 : 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: category.color
                                .withValues(alpha: isDark ? 0.5 : 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Hero(
                      tag: '${widget.heroPrefix}_title_${_currentExpense.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          _currentExpense.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: category.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Hero(
                      tag: '${widget.heroPrefix}_amt_${_currentExpense.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          '${_currentExpense.currency}${_currentExpense.amount.toStringAsFixed(_currentExpense.amount.truncateToDouble() == _currentExpense.amount ? 0 : 2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Metadata Information Card
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
                  children: [
                    _buildMetaRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date & Time',
                      value: _formatFullDate(_currentExpense.date),
                      isDark: isDark,
                    ),
                    const Divider(height: 24, thickness: 0.8),
                    _buildMetaRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Privacy',
                      value: 'Strictly Private (Encrypted for you only)',
                      isDark: isDark,
                      valueColor: FormaColors.success,
                    ),
                    if (_currentExpense.note != null &&
                        _currentExpense.note!.isNotEmpty) ...[
                      const Divider(height: 24, thickness: 0.8),
                      _buildMetaRow(
                        icon: Icons.notes_rounded,
                        label: 'Note',
                        value: _currentExpense.note!,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Quick Action Button
              FormaBounceable(
                onTap: () async {
                  await context.push('/expenses/add', extra: _currentExpense);
                  if (mounted) context.pop();
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: FormaColors.goldenYellow.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_rounded,
                          color: FormaColors.charcoal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Edit Expense',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: FormaColors.primaryAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ??
                      (isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
