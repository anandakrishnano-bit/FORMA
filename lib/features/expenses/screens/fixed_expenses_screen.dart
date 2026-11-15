import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/forma_text_field.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

class FixedExpensesScreen extends ConsumerStatefulWidget {
  const FixedExpensesScreen({super.key});

  @override
  ConsumerState<FixedExpensesScreen> createState() =>
      _FixedExpensesScreenState();
}

class _FixedExpensesScreenState extends ConsumerState<FixedExpensesScreen> {
  // Filter: 'all', 'obligations', 'habits'
  String _activeFilter = 'all';

  void _openAddFixedExpenseSheet(
      [FixedExpense? existing, bool defaultIsObligation = true]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddFixedExpenseSheet(
        existing: existing,
        defaultIsObligation: defaultIsObligation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fixedAsync = ref.watch(fixedExpensesProvider);
    final summary = ref.watch(budgetPlannerSummaryProvider);

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Commitments & Habits',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add_rounded, color: FormaColors.primaryAccent),
            tooltip: 'Add Commitment or Habit',
            onPressed: () =>
                _openAddFixedExpenseSheet(null, _activeFilter != 'habits'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Overview Summary Card (Clear Distinction: Obligations vs Habits)
            Container(
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
                        'Budget Obligations & Habits',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDark ? Colors.white : FormaColors.charcoal,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FormaColors.coralPink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Reserved: ₹${summary.upcomingFixedReserved.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: FormaColors.coralPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildSummaryMetric(
                        label: 'Obligations Reserved',
                        value:
                            '₹${summary.upcomingFixedReserved.toStringAsFixed(0)}',
                        color: FormaColors.coralPink,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryMetric(
                        label: 'Habits Daily Guide',
                        value: summary.expectedDailyHabitsAllocation > 0
                            ? '~₹${summary.expectedDailyHabitsAllocation.toStringAsFixed(0)}/d'
                            : '₹0',
                        color: FormaColors.icyBlue,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryMetric(
                        label: 'Total Oblig.',
                        value:
                            '₹${summary.totalFixedExpenses.toStringAsFixed(0)}',
                        color: isDark ? Colors.white : FormaColors.charcoal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Filter Segmented Bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? FormaColors.charcoal : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : FormaColors.concreteGrey.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  _buildFilterTab('all', 'All', isDark),
                  _buildFilterTab('obligations', 'Obligations', isDark),
                  _buildFilterTab('habits', 'Daily Habits', isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _activeFilter == 'habits'
                      ? 'Recurring Spending Habits'
                      : (_activeFilter == 'obligations'
                          ? 'Fixed Obligations'
                          : 'All Commitments & Habits'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : FormaColors.charcoal,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openAddFixedExpenseSheet(
                      null, _activeFilter != 'habits'),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    _activeFilter == 'habits' ? 'Add Habit' : 'Add New',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                      foregroundColor: FormaColors.primaryAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),

            fixedAsync.when(
              data: (list) {
                final filtered = list.where((item) {
                  if (_activeFilter == 'obligations') return item.isObligation;
                  if (_activeFilter == 'habits') return !item.isObligation;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? FormaColors.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _activeFilter == 'habits'
                              ? Icons.repeat_rounded
                              : Icons.bookmark_border_rounded,
                          size: 36,
                          color: FormaColors.concreteGrey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _activeFilter == 'habits'
                              ? 'No Spending Habits Added'
                              : 'No Commitments Added',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isDark ? Colors.white : FormaColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _activeFilter == 'habits'
                              ? 'Add regular flexible habits like daily eggs (₹20/day), milk, fruits or travel. They won\'t be deducted upfront!'
                              : 'Add fixed commitments like rent, subscriptions or tuition that are reserved upfront.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildFixedExpenseCard(context, item, isDark);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading commitments: $e'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String id, String label, bool isDark) {
    final isSelected = _activeFilter == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeFilter = id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? FormaColors.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedExpenseCard(
      BuildContext context, FixedExpense item, bool isDark) {
    final repo = ref.read(expenseRepositoryProvider);
    final isPaid = item.isPaid;
    final isPaused = item.isPaused;
    final isObligation = item.isObligation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaused
              ? FormaColors.concreteGrey.withValues(alpha: 0.3)
              : (isPaid
                  ? FormaColors.semanticSuccess.withValues(alpha: 0.35)
                  : (isDark
                      ? Colors.white10
                      : FormaColors.concreteGrey.withValues(alpha: 0.2))),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isObligation)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FormaColors.icyBlue.withValues(alpha: 0.2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.repeat_rounded,
                      size: 18,
                      color: FormaColors.charcoal,
                    ),
                  ),
                )
              else
                // Toggle paid check
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await repo
                        .updateFixedExpense(item.copyWith(isPaid: !isPaid));
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPaid
                          ? FormaColors.semanticSuccess
                          : Colors.transparent,
                      border: Border.all(
                        color: isPaid
                            ? FormaColors.semanticSuccess
                            : FormaColors.concreteGrey,
                        width: 2,
                      ),
                    ),
                    child: isPaid
                        ? const Icon(Icons.check_rounded,
                            size: 20, color: Colors.white)
                        : null,
                  ),
                ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isPaused
                                  ? FormaColors.concreteGrey
                                  : (isDark
                                      ? Colors.white
                                      : FormaColors.charcoal),
                              decoration: (isPaid && isObligation)
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isObligation
                                ? FormaColors.coralPink.withValues(alpha: 0.12)
                                : FormaColors.icyBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isObligation ? 'Obligation' : 'Habit',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isObligation
                                  ? FormaColors.coralPink
                                  : FormaColors.charcoal,
                            ),
                          ),
                        ),
                        if (isPaused) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: FormaColors.concreteGrey
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Paused',
                                style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isObligation
                          ? '${item.frequency.toUpperCase()} • Due ${DateFormat('MMM d').format(item.dueDate)}${item.category.isNotEmpty ? ' • ${item.category}' : ''}'
                          : '${item.frequency.toUpperCase()} Habit • Budget Guide${item.category.isNotEmpty ? ' • ${item.category}' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Amount & menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${item.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: (isPaid && isObligation)
                          ? FormaColors.semanticSuccess
                          : (isDark ? Colors.white : FormaColors.charcoal),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          size: 18,
                          color: FormaColors.concreteGrey,
                        ),
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          await repo.updateFixedExpense(
                              item.copyWith(isPaused: !isPaused));
                        },
                        tooltip: isPaused ? 'Resume' : 'Pause',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded,
                            size: 16, color: FormaColors.concreteGrey),
                        onPressed: () => _openAddFixedExpenseSheet(item),
                        tooltip: 'Edit',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: FormaColors.coralPink),
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await repo.deleteFixedExpense(item.id);
                        },
                        tooltip: 'Delete',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // 1-Tap 'Record Purchase Today' for Recurring Habits
          if (!isObligation) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                context.push('/expenses/add',
                    extra: PersonalExpense(
                      id: '',
                      userId: user?.uid ?? '',
                      title: item.name,
                      amount: item.amount,
                      category: item.category,
                      date: DateTime.now(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      note: 'Logged from spending habit (${item.name})',
                    ));
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: FormaColors.primaryAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: FormaColors.primaryAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_shopping_cart_rounded,
                        size: 14, color: FormaColors.charcoal),
                    const SizedBox(width: 5),
                    Text(
                      'Record Purchase Today (₹${item.amount.toStringAsFixed(0)})',
                      style: const TextStyle(
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
        ],
      ),
    );
  }
}

class _AddFixedExpenseSheet extends ConsumerStatefulWidget {
  final FixedExpense? existing;
  final bool defaultIsObligation;

  const _AddFixedExpenseSheet({this.existing, this.defaultIsObligation = true});

  @override
  ConsumerState<_AddFixedExpenseSheet> createState() =>
      _AddFixedExpenseSheetState();
}

class _AddFixedExpenseSheetState extends ConsumerState<_AddFixedExpenseSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late bool _isObligation;
  late DateTime _dueDate;
  String _frequency = 'monthly';
  String _category = 'Subscriptions';
  bool _isPaid = false;
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _obligationCategories = [
    'Rent / Housing',
    'Subscriptions',
    'Utilities',
    'Insurance & Health',
    'Education / Tuition',
    'Transport / Travel Pass',
    'Other Obligation',
  ];

  final List<String> _habitCategories = [
    'Eggs, Milk & Groceries',
    'Food and drinks',
    'Daily Transport',
    'Coffee & Snacks',
    'Personal & Fitness',
    'Other Habit',
  ];

  List<String> get _categories =>
      _isObligation ? _obligationCategories : _habitCategories;

  List<String> get _frequencies => _isObligation
      ? ['monthly', 'weekly', 'one-time', 'custom']
      : ['daily', 'weekdays', 'weekly', 'custom'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _isObligation = e.isObligation;
      _nameController.text = e.name;
      _amountController.text = e.amount.toStringAsFixed(0);
      _dueDate = e.dueDate;
      _frequency = e.frequency;
      _category = e.category;
      _noteController.text = e.note ?? '';
      _isPaid = e.isPaid;
    } else {
      _isObligation = widget.defaultIsObligation;
      _frequency = _isObligation ? 'monthly' : 'daily';
      _category =
          _isObligation ? _obligationCategories.first : _habitCategories.first;
      _dueDate = DateTime.now().add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) return;

    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a name.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(expenseRepositoryProvider);
      final expense = FixedExpense(
        id: widget.existing?.id ?? '',
        userId: user.uid,
        name: name,
        amount: amount,
        category: _category,
        dueDate: _dueDate,
        frequency: _frequency,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        isPaid: _isObligation ? _isPaid : false,
        isPaused: widget.existing?.isPaused ?? false,
        isObligation: _isObligation,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existing != null) {
        await repo.updateFixedExpense(expense);
      } else {
        await repo.addFixedExpense(expense);
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FormaColors.concreteGrey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing != null
                  ? (_isObligation
                      ? 'Edit Fixed Obligation'
                      : 'Edit Spending Habit')
                  : (_isObligation
                      ? 'Add Fixed Obligation'
                      : 'Add Spending Habit'),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? Colors.white : FormaColors.charcoal,
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Text(_errorMessage!,
                  style: const TextStyle(
                      color: FormaColors.coralPink, fontSize: 12)),
              const SizedBox(height: 10),
            ],

            // 1. Obligation vs Habit Type Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : FormaColors.concreteGrey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isObligation = true;
                          _category = _obligationCategories.first;
                          _frequency = 'monthly';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isObligation
                              ? FormaColors.primaryAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Fixed Obligation',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _isObligation
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _isObligation
                                  ? FormaColors.charcoal
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isObligation = false;
                          _category = _habitCategories.first;
                          _frequency = 'daily';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isObligation
                              ? FormaColors.icyBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Spending Habit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: !_isObligation
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: FormaColors.charcoal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Explanatory hint
            Text(
              _isObligation
                  ? 'Mandatory bills (rent, subscriptions) are reserved upfront from your budget so you don\'t accidentally spend that money.'
                  : 'Flexible recurring habits (eggs, milk, transport) are NOT deducted upfront. They guide your daily target and you log purchases as you make them.',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),

            FormaTextField(
              hint: _isObligation
                  ? 'Name (e.g. Rent, Netflix, Metro Pass)'
                  : 'Habit Name (e.g. Daily Eggs, Milk, Commute)',
              controller: _nameController,
              prefixIcon:
                  _isObligation ? Icons.bookmark_rounded : Icons.repeat_rounded,
            ),
            const SizedBox(height: 12),

            FormaTextField(
              hint: _isObligation
                  ? 'Amount (e.g. 15000)'
                  : 'Cost per occurrence (e.g. 20 for eggs)',
              controller: _amountController,
              prefixIcon: Icons.currency_rupee_rounded,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            // Category & Frequency Selectors
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : FormaColors.concreteGrey
                                  .withValues(alpha: 0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categories.contains(_category)
                            ? _category
                            : _categories.first,
                        isExpanded: true,
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : FormaColors.concreteGrey
                                  .withValues(alpha: 0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _frequencies.contains(_frequency)
                            ? _frequency
                            : _frequencies.first,
                        isExpanded: true,
                        items: _frequencies
                            .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(f.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _frequency = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Due Date (only needed for fixed obligations)
            if (_isObligation) ...[
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : FormaColors.concreteGrey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: FormaColors.primaryAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Due Date: ${DateFormat('EEEE, MMM d, yyyy').format(_dueDate)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color:
                                  isDark ? Colors.white : FormaColors.charcoal),
                        ),
                      ),
                      const Icon(Icons.edit_calendar_rounded,
                          size: 16, color: FormaColors.concreteGrey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Already paid toggle
              Row(
                children: [
                  Checkbox(
                    value: _isPaid,
                    activeColor: FormaColors.primaryAccent,
                    onChanged: (val) => setState(() => _isPaid = val ?? false),
                  ),
                  const SizedBox(width: 6),
                  const Text('Already paid for this budget period',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
            ],

            FormaButton(
              label: widget.existing != null
                  ? (_isObligation
                      ? 'Update Obligation'
                      : 'Update Spending Habit')
                  : (_isObligation ? 'Save Obligation' : 'Save Spending Habit'),
              onPressed: _isSaving ? null : _handleSave,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
