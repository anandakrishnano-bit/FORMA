import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/custom_numeric_keypad.dart';
import 'package:forma/core/components/forma_avatar.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/repositories/expense_repository.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

/// Pakee-inspired Settle Up Screen
class SettleUpScreen extends ConsumerStatefulWidget {
  final ParticipantBalance? targetBalance;

  const SettleUpScreen({super.key, this.targetBalance});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  final _noteController = TextEditingController();
  final ValueNotifier<String> _amountNotifier = ValueNotifier<String>('');

  late String _recipientUid;
  late String _recipientName;
  late double _outstandingAmount;
  bool _iAmPayer =
      true; // true = current user is paying recipient; false = recipient paid current user

  DateTime _selectedDate = DateTime.now();
  bool _useCustomKeypad = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.targetBalance != null) {
      final b = widget.targetBalance!;
      _recipientUid = b.participantUid;
      _recipientName = b.displayName;
      _iAmPayer = b.youOwe;
      _outstandingAmount = b.netBalance.abs();
      _amountNotifier.value = _outstandingAmount > 0
          ? _outstandingAmount.toStringAsFixed(
              _outstandingAmount.truncateToDouble() == _outstandingAmount
                  ? 0
                  : 2)
          : '';
    } else {
      _recipientUid = '';
      _recipientName = 'Select friend';
      _outstandingAmount = 0.0;
    }
    _amountNotifier.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountNotifier.removeListener(_onAmountChanged);
    _noteController.dispose();
    _amountNotifier.dispose();
    super.dispose();
  }

  Future<void> _recordSettlement() async {
    if (_isSaving) return;

    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) {
      setState(() => _errorMessage = 'Please sign in to record settlements.');
      return;
    }

    if (_recipientUid.isEmpty) {
      setState(() => _errorMessage =
          'Please select the person involved in the settlement.');
      return;
    }

    final amount = double.tryParse(_amountNotifier.value.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid settlement amount.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final myName =
          user.displayName?.isNotEmpty == true ? user.displayName! : 'You';
      final payerUid = _iAmPayer ? user.uid : _recipientUid;
      final payerName = _iAmPayer ? myName : _recipientName;
      final payeeUid = _iAmPayer ? _recipientUid : user.uid;
      final payeeName = _iAmPayer ? _recipientName : myName;

      final settlement = ExpenseSettlement(
        id: '',
        payerUid: payerUid,
        payerName: payerName,
        payeeUid: payeeUid,
        payeeName: payeeName,
        amount: amount,
        currency: '₹',
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : 'Manual payment record',
        paymentDate: _selectedDate,
        createdAt: DateTime.now(),
      );

      await ref.read(expenseRepositoryProvider).recordSettlement(settlement);
      HapticFeedback.mediumImpact();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to record settlement: $e';
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

    final balances = ref.watch(sharedBalancesProvider);
    final enteredAmount = double.tryParse(_amountNotifier.value.trim()) ?? 0.0;
    final remainingAfterPayment =
        (_outstandingAmount - enteredAmount).clamp(0.0, double.infinity);

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
          'Record Settlement',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _recordSettlement,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: FormaColors.primaryAccent),
                  )
                : Text(
                    'Confirm',
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

                    // 1. Amount Display Card
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
                        children: [
                          Text(
                            'SETTLEMENT PAYMENT AMOUNT',
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
                              final displayAmount = value.isEmpty ? '0' : value;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
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
                          if (_outstandingAmount > 0) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Outstanding: ₹${_outstandingAmount.toStringAsFixed(0)} • Remaining after: ₹${remainingAfterPayment.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: remainingAfterPayment == 0
                                    ? FormaColors.success
                                    : secondaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Direction & Member Selector
                    Text(
                      'Settlement Direction',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FormaBounceable(
                            onTap: () => setState(() => _iAmPayer = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _iAmPayer
                                    ? FormaColors.primaryAccent
                                    : cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _iAmPayer
                                      ? FormaColors.primaryAccent
                                      : (isDark
                                          ? Colors.white10
                                          : FormaColors.divider),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'You paid them',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: _iAmPayer
                                        ? FormaColors.charcoal
                                        : primaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FormaBounceable(
                            onTap: () => setState(() => _iAmPayer = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_iAmPayer
                                    ? FormaColors.primaryAccent
                                    : cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: !_iAmPayer
                                      ? FormaColors.primaryAccent
                                      : (isDark
                                          ? Colors.white10
                                          : FormaColors.divider),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'They paid you',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: !_iAmPayer
                                        ? FormaColors.charcoal
                                        : primaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 3. Member Selector
                    Text(
                      'Other Participant',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (balances.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _recipientName,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: balances.map((bal) {
                            final isSel = _recipientUid == bal.participantUid;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FormaBounceable(
                                onTap: () {
                                  setState(() {
                                    _recipientUid = bal.participantUid;
                                    _recipientName = bal.displayName;
                                    _outstandingAmount = bal.netBalance.abs();
                                    _iAmPayer = bal.youOwe;
                                    _amountNotifier.value = _outstandingAmount >
                                            0
                                        ? _outstandingAmount.toStringAsFixed(
                                            _outstandingAmount
                                                        .truncateToDouble() ==
                                                    _outstandingAmount
                                                ? 0
                                                : 2)
                                        : '';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? FormaColors.primaryAccent
                                            .withValues(alpha: 0.25)
                                        : cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSel
                                          ? FormaColors.primaryAccent
                                          : (isDark
                                              ? Colors.white10
                                              : FormaColors.divider),
                                      width: isSel ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      FormaAvatar(
                                        photoUrl: bal.photoUrl,
                                        name: bal.displayName,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        bal.displayName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSel
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: primaryTextColor,
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

                    const SizedBox(height: 18),

                    // 4. Note
                    Text(
                      'Payment Method or Note',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      style: TextStyle(fontSize: 14, color: primaryTextColor),
                      decoration: InputDecoration(
                        hintText: 'e.g. Paid via UPI / Cash / Google Pay',
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

                    const SizedBox(height: 16),
                    // Clarification note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FormaColors.icyBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: FormaColors.icyBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'FORMA records offline and peer payments. No bank credentials or financial transactions are handled.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : FormaColors.charcoal),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
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
