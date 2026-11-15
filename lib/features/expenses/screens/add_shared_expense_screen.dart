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
import 'package:forma/data/repositories/friends_group_repository.dart';

/// Pakee-inspired Add Shared Expense Screen
class AddSharedExpenseScreen extends ConsumerStatefulWidget {
  const AddSharedExpenseScreen({super.key});

  @override
  ConsumerState<AddSharedExpenseScreen> createState() =>
      _AddSharedExpenseScreenState();
}

class _AddSharedExpenseScreenState
    extends ConsumerState<AddSharedExpenseScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final ValueNotifier<String> _amountNotifier = ValueNotifier<String>('');

  DateTime _selectedDate = DateTime.now();
  SplitMethod _splitMethod = SplitMethod.equal;
  bool _useCustomKeypad = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Selected participants list: always includes current user by default
  late String _currentUserUid;
  late String _currentUserName;
  late List<({String uid, String name, String? photoUrl})>
      _selectedParticipants;
  late String _payerUid;

  // For Custom splits: Map of uid -> TextEditingController
  final Map<String, TextEditingController> _customShareControllers = {};
  // For Percentage splits: Map of uid -> TextEditingController
  final Map<String, TextEditingController> _percentageControllers = {};

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserUid = user?.uid ?? 'guest';
    _currentUserName =
        (user?.displayName != null && user!.displayName!.isNotEmpty)
            ? user.displayName!
            : 'You';
    _payerUid = _currentUserUid;

    _selectedParticipants = [
      (uid: _currentUserUid, name: _currentUserName, photoUrl: user?.photoURL)
    ];

    _amountNotifier.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountNotifier.removeListener(_onAmountChanged);
    _titleController.dispose();
    _noteController.dispose();
    _amountNotifier.dispose();
    for (final c in _customShareControllers.values) {
      c.dispose();
    }
    for (final c in _percentageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleParticipant(({String uid, String name, String? photoUrl}) p) {
    if (p.uid == _currentUserUid) return; // Current user always included

    setState(() {
      final exists = _selectedParticipants.any((item) => item.uid == p.uid);
      if (exists) {
        _selectedParticipants.removeWhere((item) => item.uid == p.uid);
        _customShareControllers[p.uid]?.dispose();
        _customShareControllers.remove(p.uid);
        _percentageControllers[p.uid]?.dispose();
        _percentageControllers.remove(p.uid);
        if (_payerUid == p.uid) {
          _payerUid = _currentUserUid;
        }
      } else {
        _selectedParticipants.add(p);
      }
    });
  }

  TextEditingController _getCustomController(String uid) {
    return _customShareControllers.putIfAbsent(
        uid, () => TextEditingController());
  }

  TextEditingController _getPercentageController(String uid) {
    return _percentageControllers.putIfAbsent(
        uid, () => TextEditingController());
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

  Future<void> _saveSharedExpense() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountNotifier.value.trim());

    if (amount == null || amount <= 0) {
      setState(() =>
          _errorMessage = 'Please enter an expense amount greater than 0.');
      return;
    }
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter an expense title.');
      return;
    }
    if (_selectedParticipants.length < 2) {
      setState(() =>
          _errorMessage = 'Please select at least one friend to split with.');
      return;
    }

    // Build ParticipantShare list according to splitMethod
    List<ParticipantShare> shares = [];

    if (_splitMethod == SplitMethod.equal) {
      shares = ExpenseRepository.calculateEqualSplit(
        totalAmount: amount,
        participants: _selectedParticipants,
        payerUid: _payerUid,
      );
    } else if (_splitMethod == SplitMethod.custom) {
      // Validate custom allocations sum to total
      int totalAssignedMinor = 0;
      final totalExpectedMinor = (amount * 100).round();

      for (final p in _selectedParticipants) {
        final valStr = _getCustomController(p.uid).text.trim();
        final share = double.tryParse(valStr) ?? 0.0;
        final shareMinor = (share * 100).round();
        totalAssignedMinor += shareMinor;

        shares.add(ParticipantShare(
          userId: p.uid,
          displayName: p.name,
          photoUrl: p.photoUrl,
          assignedAmount: share,
          amountPaid: p.uid == _payerUid ? amount : 0.0,
        ));
      }

      if ((totalAssignedMinor - totalExpectedMinor).abs() > 1) {
        final assignedTotal = totalAssignedMinor / 100.0;
        setState(() {
          _errorMessage =
              'Custom shares total ₹${assignedTotal.toStringAsFixed(2)}, but total expense is ₹${amount.toStringAsFixed(2)}. Please balance the amounts.';
        });
        return;
      }
    } else if (_splitMethod == SplitMethod.percentage) {
      // Validate percentages sum to 100%
      double totalPercent = 0.0;
      final percentList =
          <({String uid, String name, String? photoUrl, double percent})>[];

      for (final p in _selectedParticipants) {
        final valStr = _getPercentageController(p.uid).text.trim();
        final pct = double.tryParse(valStr) ?? 0.0;
        totalPercent += pct;
        percentList.add(
            (uid: p.uid, name: p.name, photoUrl: p.photoUrl, percent: pct));
      }

      if ((totalPercent - 100.0).abs() > 0.01) {
        setState(() {
          _errorMessage =
              'Percentages must sum to exactly 100% (currently ${totalPercent.toStringAsFixed(1)}%).';
        });
        return;
      }

      shares = ExpenseRepository.calculatePercentageSplit(
        totalAmount: amount,
        participants: percentList,
        payerUid: _payerUid,
      );
    }

    final payerName = _selectedParticipants
        .firstWhere(
          (p) => p.uid == _payerUid,
          orElse: () => _selectedParticipants.first,
        )
        .name;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final expense = SharedExpense(
        id: '',
        title: title,
        totalAmount: amount,
        currency: '₹',
        paidByUid: _payerUid,
        paidByName: payerName,
        date: _selectedDate,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        participants: shares,
        splitMethod: _splitMethod,
        createdBy: _currentUserUid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(expenseRepositoryProvider).addSharedExpense(expense);
      HapticFeedback.mediumImpact();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save shared expense: $e';
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

    final friendsAsync = ref.watch(confirmedFriendsProvider);
    final totalAmount = double.tryParse(_amountNotifier.value.trim()) ?? 0.0;

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
          'Add Shared Expense',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSharedExpense,
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
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
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
                            color:
                                FormaColors.coralPink.withValues(alpha: 0.15),
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

                      // 1. Featured Amount Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 20),
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
                              'SHARED EXPENSE TOTAL',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<String>(
                              valueListenable: _amountNotifier,
                              builder: (context, value, _) {
                                final displayAmount =
                                    value.isEmpty ? '0' : value;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '₹',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: FormaColors.goldenYellow,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      displayAmount,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 50,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.2,
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 2. Title field
                      Text(
                        'Expense Title',
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
                          hintText: 'e.g. Dinner, Taxi fare, Groceries',
                          hintStyle: TextStyle(
                              color: secondaryTextColor.withValues(alpha: 0.6)),
                          prefixIcon: const Icon(Icons.receipt_rounded,
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
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Paid By Selector
                      Text(
                        'Who Paid?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _selectedParticipants.map((p) {
                            final isPayer = _payerUid == p.uid;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FormaBounceable(
                                onTap: () => setState(() => _payerUid = p.uid),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isPayer
                                        ? FormaColors.primaryAccent
                                        : cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isPayer
                                          ? FormaColors.primaryAccent
                                          : (isDark
                                              ? Colors.white10
                                              : FormaColors.divider),
                                    ),
                                  ),
                                  child: Text(
                                    p.uid == _currentUserUid ? 'You' : p.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isPayer
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isPayer
                                          ? FormaColors.charcoal
                                          : primaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4. Participants Selection (Friends)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Participants (${_selectedParticipants.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            'Tap to add/remove',
                            style: TextStyle(
                                fontSize: 12, color: secondaryTextColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      friendsAsync.when(
                        data: (friends) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Current user badge (always selected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: FormaColors.primaryAccent
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: FormaColors.primaryAccent),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_rounded,
                                        size: 16,
                                        color: FormaColors.primaryAccent),
                                    const SizedBox(width: 6),
                                    Text(
                                      'You',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: primaryTextColor),
                                    ),
                                  ],
                                ),
                              ),
                              // Confirmed friends
                              ...friends.map((friend) {
                                final isSelected = _selectedParticipants
                                    .any((p) => p.uid == friend.userId);
                                return FormaBounceable(
                                  onTap: () => _toggleParticipant((
                                    uid: friend.userId,
                                    name: friend.displayName,
                                    photoUrl: null,
                                  )),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? FormaColors.primaryAccent
                                              .withValues(alpha: 0.25)
                                          : cardBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? FormaColors.primaryAccent
                                            : (isDark
                                                ? Colors.white10
                                                : FormaColors.divider),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons
                                                  .add_circle_outline_rounded,
                                          size: 16,
                                          color: isSelected
                                              ? FormaColors.primaryAccent
                                              : secondaryTextColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          friend.displayName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? primaryTextColor
                                                : secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                        loading: () => const SizedBox(
                            height: 20, child: LinearProgressIndicator()),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 20),

                      // 5. Split Method Selector: Equal, Custom, Percentage
                      Text(
                        'Split Method',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : FormaColors.divider),
                        ),
                        child: Row(
                          children: SplitMethod.values.map((method) {
                            final isSel = _splitMethod == method;
                            final label = method == SplitMethod.equal
                                ? 'Equal Split'
                                : (method == SplitMethod.custom
                                    ? 'Custom'
                                    : 'Percentage');
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _splitMethod = method),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? FormaColors.primaryAccent
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSel
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSel
                                            ? FormaColors.charcoal
                                            : secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 6. Split Input & Calculated Shares
                      if (_splitMethod == SplitMethod.equal) ...[
                        // Equal split summary card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : FormaColors.divider),
                          ),
                          child: Column(
                            children: _selectedParticipants.map((p) {
                              final count = _selectedParticipants.length;
                              final share =
                                  count > 0 ? (totalAmount / count) : 0.0;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      p.uid == _currentUserUid ? 'You' : p.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: primaryTextColor),
                                    ),
                                    Text(
                                      '₹${share.toStringAsFixed(share.truncateToDouble() == share ? 0 : 2)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: FormaColors.primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ] else if (_splitMethod == SplitMethod.custom) ...[
                        // Custom split input fields
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : FormaColors.divider),
                          ),
                          child: Column(
                            children: _selectedParticipants.map((p) {
                              final ctrl = _getCustomController(p.uid);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.uid == _currentUserUid
                                            ? 'You'
                                            : p.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: primaryTextColor),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: TextField(
                                        controller: ctrl,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          prefixText: '₹ ',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ] else ...[
                        // Percentage split input fields
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : FormaColors.divider),
                          ),
                          child: Column(
                            children: _selectedParticipants.map((p) {
                              final ctrl = _getPercentageController(p.uid);
                              final pct =
                                  double.tryParse(ctrl.text.trim()) ?? 0.0;
                              final calcShare = (totalAmount * pct) / 100.0;

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.uid == _currentUserUid
                                                ? 'You'
                                                : p.name,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: primaryTextColor),
                                          ),
                                          Text(
                                            '₹${calcShare.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    FormaColors.primaryAccent),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: TextField(
                                        controller: ctrl,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          suffixText: '%',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // 7. Date & Optional Note
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
                                color: isDark
                                    ? Colors.white10
                                    : FormaColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 20,
                                      color: FormaColors.primaryAccent),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor),
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
                          hintText: 'e.g. Split equally for team dinner',
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
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Keypad
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
      ),
    );
  }
}
