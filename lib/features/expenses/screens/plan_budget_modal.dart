import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/forma_text_field.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

/// Modal bottom sheet to create or edit a Personal Budget Plan
Future<void> showPlanBudgetModal(BuildContext context,
    {BudgetPlan? existingPlan}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PlanBudgetModal(existingPlan: existingPlan),
  );
}

class PlanBudgetModal extends ConsumerStatefulWidget {
  final BudgetPlan? existingPlan;

  const PlanBudgetModal({super.key, this.existingPlan});

  @override
  ConsumerState<PlanBudgetModal> createState() => _PlanBudgetModalState();
}

class _PlanBudgetModalState extends ConsumerState<PlanBudgetModal> {
  final _amountController = TextEditingController();
  final _daysController = TextEditingController(text: '30');
  final _descriptionController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedCurrency = '₹';
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _currencies = ['₹', '\$', '€', '£', 'A\$', '¥', 'AED'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.existingPlan != null) {
      final p = widget.existingPlan!;
      _amountController.text = p.totalBudget.toStringAsFixed(0);
      _startDate = p.startDate;
      _endDate = p.endDate;
      _daysController.text = p.totalDays.toString();
      _selectedCurrency = p.currency;
      _descriptionController.text = p.description ?? '';
    } else {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = _startDate.add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _daysController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onDaysChanged(String val) {
    final days = int.tryParse(val.trim());
    if (days != null && days > 0) {
      setState(() {
        _endDate = _startDate.add(Duration(days: days - 1));
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        final days = int.tryParse(_daysController.text.trim()) ?? 30;
        _endDate = _startDate.add(Duration(days: days - 1));
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        final diff = _endDate.difference(_startDate).inDays + 1;
        _daysController.text = (diff > 0 ? diff : 1).toString();
      });
    }
  }

  Future<void> _handleSave() async {
    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) {
      setState(() => _errorMessage = 'Please sign in to manage your budget.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() =>
          _errorMessage = 'Please enter a valid available budget amount.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(expenseRepositoryProvider);
      final plan = BudgetPlan(
        id: widget.existingPlan?.id ?? 'active_plan',
        userId: user.uid,
        totalBudget: amount,
        startDate: _startDate,
        endDate: _endDate,
        currency: _selectedCurrency,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isFlexibleMode: widget.existingPlan?.isFlexibleMode ?? false,
        createdAt: widget.existingPlan?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveBudgetPlan(plan);

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Budget plan saved: $_selectedCurrency${amount.toStringAsFixed(0)} for ${plan.totalDays} days',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: FormaColors.charcoal,
              ),
            ),
            backgroundColor: FormaColors.primaryAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save budget plan: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final maxHeight = mediaQuery.size.height * 0.88;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: SafeArea(
        bottom: true,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingPlan != null
                          ? 'Edit Budget Plan'
                          : 'Plan My Budget',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: isDark ? Colors.white : FormaColors.charcoal,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Enter your available money and how long it needs to last. FORMA calculates a daily spending allowance and tracks carryover.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color:
                                FormaColors.coralPink.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: FormaColors.coralPink
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: FormaColors.coralPink,
                            ),
                          ),
                        ),
                      ],

                      // Currency & Amount
                      Row(
                        children: [
                          // Currency dropdown
                          Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : FormaColors.concreteGrey
                                        .withValues(alpha: 0.25),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCurrency,
                                items: _currencies
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 16)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedCurrency = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FormaTextField(
                              hint: 'Available Money (e.g. 15000)',
                              controller: _amountController,
                              prefixIcon: Icons.account_balance_wallet_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Duration: Days & Date Range
                      Row(
                        children: [
                          Expanded(
                            child: FormaTextField(
                              hint: 'Number of Days',
                              controller: _daysController,
                              prefixIcon: Icons.calendar_today_rounded,
                              keyboardType: TextInputType.number,
                              onChanged: _onDaysChanged,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickStartDate,
                              child: Container(
                                height: 54,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : FormaColors.concreteGrey
                                            .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Date',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? FormaColors.darkSecondaryText
                                            : FormaColors.lightSecondaryText,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM d, yyyy')
                                          .format(_startDate),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white
                                            : FormaColors.charcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // End Date Picker Pill
                      GestureDetector(
                        onTap: _pickEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : FormaColors.concreteGrey
                                      .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available_rounded,
                                  size: 18, color: FormaColors.primaryAccent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Period Ends: ${DateFormat('EEEE, MMM d, yyyy').format(_endDate)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white
                                        : FormaColors.charcoal,
                                  ),
                                ),
                              ),
                              const Icon(Icons.edit_calendar_rounded,
                                  size: 16, color: FormaColors.concreteGrey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Optional Description
                      FormaTextField(
                        hint:
                            'Budget Description (e.g. November Living Expenses, Travel)',
                        controller: _descriptionController,
                        prefixIcon: Icons.notes_rounded,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // 3. Persistent Sticky Footer (Confirm Button ALWAYS Visible & Clickable)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : FormaColors.divider.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: FormaButton(
                  label: widget.existingPlan != null
                      ? 'Update Budget Plan'
                      : 'Save Budget Plan',
                  onPressed: _isSaving ? null : _handleSave,
                  isLoading: _isSaving,
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
