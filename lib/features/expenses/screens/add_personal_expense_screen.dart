import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/custom_numeric_keypad.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/repositories/expense_repository.dart';

/// Pakee-inspired Add Personal Expense Screen
class AddPersonalExpenseScreen extends ConsumerStatefulWidget {
  final PersonalExpense? existingExpense;

  const AddPersonalExpenseScreen({super.key, this.existingExpense});

  @override
  ConsumerState<AddPersonalExpenseScreen> createState() =>
      _AddPersonalExpenseScreenState();
}

class _AddPersonalExpenseScreenState
    extends ConsumerState<AddPersonalExpenseScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final ValueNotifier<String> _amountNotifier = ValueNotifier<String>('');

  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _useCustomKeypad = true;
  bool _isSaving = false;
  String? _errorMessage;

  final List<ExpenseCategory> _categories =
      List.from(ExpenseCategory.defaultCategories);

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final exp = widget.existingExpense!;
      _titleController.text = exp.title;
      _noteController.text = exp.note ?? '';
      _amountNotifier.value = exp.amount
          .toStringAsFixed(exp.amount.truncateToDouble() == exp.amount ? 0 : 2);
      _selectedCategory = exp.category;
      _selectedDate = exp.date;
    } else {
      _selectedCategory = ExpenseCategory.defaultCategories.first.name;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _amountNotifier.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FormaColors.primaryAccent,
              onPrimary: FormaColors.charcoal,
              surface: isDark ? FormaColors.charcoal : Colors.white,
              onSurface: isDark ? Colors.white : FormaColors.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAddCustomCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? FormaColors.charcoal
              : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'New Category',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Gym Gear, Pets, Hobbies',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = nameController.text.trim();
                if (text.isNotEmpty) {
                  final newCat = ExpenseCategory(
                    id: text.toLowerCase().replaceAll(' ', '_'),
                    name: text,
                    icon: Icons.label_rounded,
                    color: FormaColors.goldenYellow,
                    isCustom: true,
                  );
                  setState(() {
                    _categories.add(newCat);
                    _selectedCategory = newCat.name;
                  });
                  Navigator.of(ctx).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FormaColors.primaryAccent,
                foregroundColor: FormaColors.charcoal,
              ),
              child: const Text('Add Category',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveExpense() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final amountStr = _amountNotifier.value.trim();
    final amount = double.tryParse(amountStr);

    if (amount == null || amount <= 0) {
      setState(() =>
          _errorMessage = 'Please enter an expense amount greater than 0.');
      return;
    }
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter what this expense was for.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(
          () => _errorMessage = 'Please sign in to save personal expenses.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(expenseRepositoryProvider);

      if (widget.existingExpense != null) {
        final updated = widget.existingExpense!.copyWith(
          title: title,
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          note: _noteController.text.trim().isNotEmpty
              ? _noteController.text.trim()
              : null,
          updatedAt: DateTime.now(),
        );
        await repo.updatePersonalExpense(updated);
      } else {
        final expense = PersonalExpense(
          id: '',
          userId: user.uid,
          title: title,
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          note: _noteController.text.trim().isNotEmpty
              ? _noteController.text.trim()
              : null,
          currency: '₹',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.addPersonalExpense(expense);
      }

      HapticFeedback.mediumImpact();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save expense: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: primaryTextColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.existingExpense != null ? 'Edit Expense' : 'Add Expense',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveExpense,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: FormaColors.primaryAccent),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: FormaColors.primaryAccent,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: FormaColors.coralPink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: FormaColors.coralPink),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: FormaColors.coralPink, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: FormaColors.coralPink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 1. Visual Center: Large Amount Display Card (Pakee inspiration)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 20),
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
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'ENTER AMOUNT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<String>(
                            valueListenable: _amountNotifier,
                            builder: (context, value, _) {
                              final displayAmount = value.isEmpty ? '0' : value;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '₹',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                      color: FormaColors.goldenYellow,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    displayAmount,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 54,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.5,
                                      color: value.isEmpty
                                          ? secondaryTextColor.withValues(
                                              alpha: 0.5)
                                          : primaryTextColor,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Indian Rupee (INR)',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. What was this for? Title field
                    Text(
                      'What was this for?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor),
                      decoration: InputDecoration(
                        hintText: 'e.g. Lunch, Bus ticket, Supplements',
                        hintStyle: TextStyle(
                            color: secondaryTextColor.withValues(alpha: 0.6)),
                        prefixIcon: const Icon(Icons.edit_note_rounded,
                            color: FormaColors.primaryAccent),
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : FormaColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : FormaColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                              color: FormaColors.primaryAccent, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. Category Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Category',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: _showAddCustomCategoryDialog,
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 16, color: FormaColors.primaryAccent),
                              SizedBox(width: 4),
                              Text(
                                'Custom',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: FormaColors.primaryAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _categories.map((cat) {
                          final isSel = _selectedCategory.toLowerCase() ==
                              cat.name.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FormaBounceable(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategory = cat.name);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? cat.color.withValues(
                                          alpha: isDark ? 0.35 : 0.2)
                                      : cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSel
                                        ? cat.color
                                        : (isDark
                                            ? Colors.white10
                                            : FormaColors.divider),
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(cat.icon,
                                        size: 18,
                                        color: isSel
                                            ? cat.color
                                            : secondaryTextColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSel
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSel
                                            ? primaryTextColor
                                            : secondaryTextColor,
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

                    const SizedBox(height: 20),

                    // 4. Date & Time Selector
                    Text(
                      'Date',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormaBounceable(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                isDark ? Colors.white10 : FormaColors.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 20, color: FormaColors.primaryAccent),
                                const SizedBox(width: 12),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: secondaryTextColor),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 5. Optional Note Field
                    Text(
                      'Optional Note',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      style: TextStyle(fontSize: 14, color: primaryTextColor),
                      decoration: InputDecoration(
                        hintText: 'Add extra details, place, or reason...',
                        hintStyle: TextStyle(
                            color: secondaryTextColor.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : FormaColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : FormaColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                              color: FormaColors.primaryAccent, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 6. Custom Numeric Keypad or System Keyboard toggle
            if (_useCustomKeypad)
              CustomNumericKeypad(
                amountNotifier: _amountNotifier,
                isDark: isDark,
                showDoneButton: false,
                onSwitchToSystemKeyboard: () {
                  setState(() => _useCustomKeypad = false);
                },
              )
            else
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextButton.icon(
                  icon: const Icon(Icons.dialpad_rounded),
                  label: const Text('Switch back to tactile numeric keypad'),
                  onPressed: () => setState(() => _useCustomKeypad = true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
