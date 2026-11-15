import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

/// Stream of personal expenses for the current user
final personalExpensesStreamProvider =
    StreamProvider<List<PersonalExpense>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(expenseRepositoryProvider).streamPersonalExpenses(user.uid);
});

/// Stream of shared expenses for the current user
final sharedExpensesStreamProvider = StreamProvider<List<SharedExpense>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(expenseRepositoryProvider).streamSharedExpenses(user.uid);
});

/// Stream of settlement records involving the current user
final settlementsStreamProvider =
    StreamProvider<List<ExpenseSettlement>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(expenseRepositoryProvider).streamSettlements(user.uid);
});

/// Calculated balances between current user and all shared participants
final sharedBalancesProvider = Provider<List<ParticipantBalance>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  final sharedAsync = ref.watch(sharedExpensesStreamProvider);
  final settlementsAsync = ref.watch(settlementsStreamProvider);

  if (user == null) return [];
  final shared = sharedAsync.valueOrNull ?? [];
  final settlements = settlementsAsync.valueOrNull ?? [];

  return ExpenseRepository.computeBalances(
    currentUserUid: user.uid,
    sharedExpenses: shared,
    settlements: settlements,
  );
});

/// Stream of active Budget Plan for the user
final activeBudgetPlanProvider = StreamProvider<BudgetPlan?>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(expenseRepositoryProvider).streamActiveBudget(user.uid);
});

/// Stream of fixed recurring/committed expenses
final fixedExpensesProvider = StreamProvider<List<FixedExpense>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(expenseRepositoryProvider).streamFixedExpenses(user.uid);
});

/// Grounded, reactive Budget Planner summary
final budgetPlannerSummaryProvider = Provider<BudgetPlannerSummary>((ref) {
  final planAsync = ref.watch(activeBudgetPlanProvider);
  final expensesAsync = ref.watch(personalExpensesStreamProvider);
  final fixedAsync = ref.watch(fixedExpensesProvider);

  final plan = planAsync.valueOrNull;
  final allExpenses = expensesAsync.valueOrNull ?? [];
  final allFixed = fixedAsync.valueOrNull ?? [];

  if (plan == null) {
    return BudgetPlannerSummary.empty;
  }

  return ExpenseRepository.computeBudgetSummary(
    plan: plan,
    expenses: allExpenses,
    fixedExpenses: allFixed,
  );
});

/// Repository for both Personal Expenses and Shared Expenses & Settlements
class ExpenseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ExpenseRepository(this._firestore, this._auth);

  String? get currentUid => _auth.currentUser?.uid;

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSONAL EXPENSES (STRICTLY PRIVATE: users/{uid}/personalExpenses)
  // ═══════════════════════════════════════════════════════════════════════════

  CollectionReference _personalExpensesCol(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('personalExpenses');
  }

  CollectionReference _customCategoriesCol(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('customExpenseCategories');
  }

  Stream<List<PersonalExpense>> streamPersonalExpenses(String uid) {
    return _personalExpensesCol(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PersonalExpense.fromFirestore(doc))
            .toList());
  }

  Future<void> addPersonalExpense(PersonalExpense expense) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _personalExpensesCol(uid).add(expense.toMap());
  }

  Future<void> updatePersonalExpense(PersonalExpense expense) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _personalExpensesCol(uid).doc(expense.id).update(expense.toMap());
  }

  Future<void> deletePersonalExpense(String expenseId) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _personalExpensesCol(uid).doc(expenseId).delete();
  }

  Stream<List<ExpenseCategory>> streamCustomCategories(String uid) {
    return _customCategoriesCol(uid).snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            ExpenseCategory.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> addCustomCategory(ExpenseCategory category) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _customCategoriesCol(uid).doc(category.id).set(category.toMap());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUDGET PLANNER & FIXED COMMITMENTS (users/{uid}/budget & fixedExpenses)
  // ═══════════════════════════════════════════════════════════════════════════

  DocumentReference _activeBudgetDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('budget')
        .doc('active_plan');
  }

  CollectionReference _fixedExpensesCol(String uid) {
    return _firestore.collection('users').doc(uid).collection('fixedExpenses');
  }

  Stream<BudgetPlan?> streamActiveBudget(String uid) {
    return _activeBudgetDoc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return BudgetPlan.fromFirestore(doc);
    });
  }

  Future<void> saveBudgetPlan(BudgetPlan plan) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _activeBudgetDoc(uid).set(plan.toMap(), SetOptions(merge: true));
  }

  Stream<List<FixedExpense>> streamFixedExpenses(String uid) {
    return _fixedExpensesCol(uid).orderBy('dueDate').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => FixedExpense.fromFirestore(doc))
            .toList());
  }

  Future<void> addFixedExpense(FixedExpense expense) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _fixedExpensesCol(uid).add(expense.toMap());
  }

  Future<void> updateFixedExpense(FixedExpense expense) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _fixedExpensesCol(uid).doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteFixedExpense(String fixedExpenseId) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _fixedExpensesCol(uid).doc(fixedExpenseId).delete();
  }

  /// Grounded, transparent budget calculations using minor units integer math
  static BudgetPlannerSummary computeBudgetSummary({
    required BudgetPlan plan,
    required List<PersonalExpense> expenses,
    required List<FixedExpense> fixedExpenses,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final periodStart =
        DateTime(plan.startDate.year, plan.startDate.month, plan.startDate.day);
    final periodEnd = DateTime(
        plan.endDate.year, plan.endDate.month, plan.endDate.day, 23, 59, 59);

    // 1. Variable expenses falling in the budget period
    final periodExpenses = expenses.where((e) {
      return !e.date.isBefore(periodStart) && !e.date.isAfter(periodEnd);
    }).toList();

    int variableSpentCents = 0;
    int todaySpentCents = 0;

    for (final e in periodExpenses) {
      variableSpentCents += e.amountInMinorUnits;
      if (e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day) {
        todaySpentCents += e.amountInMinorUnits;
      }
    }

    // 2. Fixed Obligations vs Recurring Spending Habits
    final activeFixed = fixedExpenses.where((f) => !f.isPaused).toList();

    int totalFixedCents = 0;
    int paidFixedCents = 0;
    int upcomingReservedCents = 0;

    int expectedRecurringHabitsTotalCents = 0;
    int expectedDailyHabitsCents = 0;
    final habitNames = <String>[];

    final daysRemaining = plan.daysRemaining;
    final effectiveDays = daysRemaining > 0 ? daysRemaining : 1;

    for (final f in activeFixed) {
      if (f.isObligation) {
        // Genuine Fixed Obligation (Rent, Subscriptions, Utilities, Tuition)
        final due = DateTime(f.dueDate.year, f.dueDate.month, f.dueDate.day);
        final isInPeriod =
            !due.isBefore(periodStart) && !due.isAfter(periodEnd);

        if (isInPeriod) {
          totalFixedCents += f.amountCents;
          if (f.isPaid) {
            paidFixedCents += f.amountCents;
          } else {
            upcomingReservedCents += f.amountCents;
          }
        }
      } else {
        // Flexible Recurring Spending Habit (Daily Eggs, Groceries, Daily Transport, Snacks)
        // NOT reserved upfront! Calculated as spending guidance only.
        habitNames.add(f.name);
        int habitRemainingOccurrences = 0;
        int habitDailyCents = 0;

        if (f.frequency == 'daily') {
          habitRemainingOccurrences = effectiveDays;
          habitDailyCents = f.amountCents;
        } else if (f.frequency == 'weekdays') {
          // Estimate 5/7 of remaining days
          habitRemainingOccurrences = ((effectiveDays * 5) / 7).round();
          habitDailyCents =
              (habitRemainingOccurrences * f.amountCents) ~/ effectiveDays;
        } else if (f.frequency == 'weekly') {
          habitRemainingOccurrences = (effectiveDays / 7.0).ceil();
          habitDailyCents =
              (habitRemainingOccurrences * f.amountCents) ~/ effectiveDays;
        } else {
          habitRemainingOccurrences = 1;
          habitDailyCents = f.amountCents ~/ effectiveDays;
        }

        final habitTotalCents = habitRemainingOccurrences * f.amountCents;
        expectedRecurringHabitsTotalCents += habitTotalCents;
        expectedDailyHabitsCents += habitDailyCents;
      }
    }

    // 3. Available and Remaining Budget
    // Only actual variable purchases and unpaid fixed obligations reduce spendable budget!
    final totalBudgetCents = plan.totalBudgetCents;
    final remainingSpendableCents =
        totalBudgetCents - variableSpentCents - upcomingReservedCents;

    final isOverBudget = remainingSpendableCents < 0;

    // 4. Suggested Daily Allowance
    final suggestedDailyAllowanceCents =
        isOverBudget ? 0 : (remainingSpendableCents ~/ effectiveDays);

    final todayRemainingAllowanceCents =
        suggestedDailyAllowanceCents - todaySpentCents;

    // 5. Transparent, traceable suggestions
    final suggestions = <String>[];
    if (daysRemaining > 0) {
      suggestions
          .add('You have $daysRemaining days remaining in this budget period.');
    } else {
      suggestions.add('This budget period has concluded.');
    }

    if (upcomingReservedCents > 0) {
      suggestions.add(
          '${plan.currency}${(upcomingReservedCents / 100).toStringAsFixed(0)} reserved for upcoming fixed obligations.');
    }

    if (isOverBudget) {
      final overCents = -remainingSpendableCents;
      suggestions.add(
          'Currently ${plan.currency}${(overCents / 100).toStringAsFixed(0)} over total allocated budget.');
    } else if (todaySpentCents > suggestedDailyAllowanceCents &&
        suggestedDailyAllowanceCents > 0) {
      suggestions.add(
          'Today\'s spending is slightly above today\'s suggested allowance.');
    } else {
      suggestions.add(
          'Suggested daily allowance for remaining days is ${plan.currency}${(suggestedDailyAllowanceCents / 100).toStringAsFixed(0)}.');
    }

    if (expectedDailyHabitsCents > 0) {
      final habitsStr = habitNames.take(2).join(', ');
      final habitsDaily = (expectedDailyHabitsCents / 100).toStringAsFixed(0);
      final otherDaily =
          ((suggestedDailyAllowanceCents - expectedDailyHabitsCents)
                      .clamp(0, 999999999) /
                  100)
              .toStringAsFixed(0);
      suggestions.add(
          'Includes ~${plan.currency}$habitsDaily/day for recurring habits ($habitsStr), leaving ~${plan.currency}$otherDaily/day for other spending.');
    }

    return BudgetPlannerSummary(
      plan: plan,
      totalBudget: totalBudgetCents / 100.0,
      variableSpent: variableSpentCents / 100.0,
      totalFixedExpenses: totalFixedCents / 100.0,
      paidFixedExpenses: paidFixedCents / 100.0,
      upcomingFixedReserved: upcomingReservedCents / 100.0,
      remainingSpendableBudget: remainingSpendableCents / 100.0,
      suggestedDailyAllowance: suggestedDailyAllowanceCents / 100.0,
      todayActualSpent: todaySpentCents / 100.0,
      todayRemainingAllowance: todayRemainingAllowanceCents / 100.0,
      daysRemaining: daysRemaining,
      totalDays: plan.totalDays,
      isOverBudget: isOverBudget,
      suggestions: suggestions,
      expectedRecurringHabitsTotal: expectedRecurringHabitsTotalCents / 100.0,
      expectedDailyHabitsAllocation: expectedDailyHabitsCents / 100.0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED EXPENSES (sharedExpenses/{expenseId})
  // ═══════════════════════════════════════════════════════════════════════════

  CollectionReference get _sharedExpensesCol =>
      _firestore.collection('sharedExpenses');
  CollectionReference get _settlementsCol =>
      _firestore.collection('expenseSettlements');

  Stream<List<SharedExpense>> streamSharedExpenses(String uid) {
    return _sharedExpensesCol
        .where('participantUids', arrayContains: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SharedExpense.fromFirestore(doc))
            .toList());
  }

  Future<void> addSharedExpense(SharedExpense expense) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    // Server-side / local split validation with integer minor units
    _validateSplit(expense);

    await _sharedExpensesCol.add(expense.toMap());
  }

  Future<void> updateSharedExpense(SharedExpense expense) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    _validateSplit(expense);
    await _sharedExpensesCol.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteSharedExpense(String expenseId) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    await _sharedExpensesCol.doc(expenseId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTLEMENTS (expenseSettlements/{settlementId})
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<ExpenseSettlement>> streamSettlements(String uid) {
    // Return settlements where current user is either payer or payee
    return _settlementsCol
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseSettlement.fromFirestore(doc))
            .where((s) => s.payerUid == uid || s.payeeUid == uid)
            .toList());
  }

  Future<void> recordSettlement(ExpenseSettlement settlement) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Not authenticated');

    if (settlement.amount <= 0) {
      throw ArgumentError('Settlement amount must be positive.');
    }

    await _settlementsCol.add(settlement.toMap());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SPLIT ALLOCATION & EXACT DECIMAL ARITHMETIC
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculates equal split portions handling minor-unit rounding differences cleanly
  static List<ParticipantShare> calculateEqualSplit({
    required double totalAmount,
    required List<({String uid, String name, String? photoUrl})> participants,
    required String payerUid,
  }) {
    if (participants.isEmpty) return [];

    final totalMinor = (totalAmount * 100).round();
    final count = participants.length;
    final baseMinor = totalMinor ~/ count;
    final remainder = totalMinor % count;

    final result = <ParticipantShare>[];
    for (int i = 0; i < count; i++) {
      final p = participants[i];
      // Distribute remainder 1 paise at a time to ensure exact sum
      final allocatedMinor = baseMinor + (i < remainder ? 1 : 0);
      final shareAmount = allocatedMinor / 100.0;
      final paidAmount = (p.uid == payerUid) ? totalAmount : 0.0;

      result.add(ParticipantShare(
        userId: p.uid,
        displayName: p.name,
        photoUrl: p.photoUrl,
        assignedAmount: shareAmount,
        percentage: (shareAmount / totalAmount) * 100,
        amountPaid: paidAmount,
      ));
    }

    return result;
  }

  /// Calculates percentage split portions handling minor-unit rounding differences
  static List<ParticipantShare> calculatePercentageSplit({
    required double totalAmount,
    required List<({String uid, String name, String? photoUrl, double percent})>
        participants,
    required String payerUid,
  }) {
    if (participants.isEmpty) return [];

    final totalMinor = (totalAmount * 100).round();
    int allocatedSum = 0;
    final result = <ParticipantShare>[];

    for (int i = 0; i < participants.length; i++) {
      final p = participants[i];
      int shareMinor;
      if (i == participants.length - 1) {
        // Last participant absorbs any rounding difference to make sum exactly equal totalMinor
        shareMinor = totalMinor - allocatedSum;
      } else {
        shareMinor = ((totalMinor * p.percent) / 100.0).round();
        allocatedSum += shareMinor;
      }

      final shareAmount = shareMinor / 100.0;
      final paidAmount = (p.uid == payerUid) ? totalAmount : 0.0;

      result.add(ParticipantShare(
        userId: p.uid,
        displayName: p.name,
        photoUrl: p.photoUrl,
        assignedAmount: shareAmount,
        percentage: p.percent,
        amountPaid: paidAmount,
      ));
    }

    return result;
  }

  void _validateSplit(SharedExpense expense) {
    if (expense.totalAmount <= 0) {
      throw ArgumentError('Total amount must be greater than zero.');
    }
    if (expense.participants.isEmpty) {
      throw ArgumentError('At least one participant is required.');
    }

    final totalMinor = expense.totalInMinorUnits;
    int sumAssignedMinor = 0;

    for (final p in expense.participants) {
      if (p.assignedAmount < 0) {
        throw ArgumentError('Assigned share cannot be negative.');
      }
      sumAssignedMinor += p.assignedInMinorUnits;
    }

    // Difference must be zero or at most 1 minor unit due to rounding
    if ((sumAssignedMinor - totalMinor).abs() > 1) {
      throw ArgumentError(
        'Participant shares (₹${(sumAssignedMinor / 100).toStringAsFixed(2)}) do not match total expense amount (₹${expense.totalAmount.toStringAsFixed(2)}).',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSISTENT LEDGER & BALANCE COMPUTATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculates who owes whom by examining all shared expenses and settlement records
  static List<ParticipantBalance> computeBalances({
    required String currentUserUid,
    required List<SharedExpense> sharedExpenses,
    required List<ExpenseSettlement> settlements,
  }) {
    // Map of participantUid -> ledger stats
    final participantMap = <String,
        ({
      String name,
      String? photoUrl,
      int theyOweYouMinor,
      int youOweThemMinor,
      int settledToYouMinor,
      int settledByYouMinor,
    })>{};

    void ensureParticipant(String uid, String name, String? photoUrl) {
      if (uid == currentUserUid) return;
      if (!participantMap.containsKey(uid)) {
        participantMap[uid] = (
          name: name,
          photoUrl: photoUrl,
          theyOweYouMinor: 0,
          youOweThemMinor: 0,
          settledToYouMinor: 0,
          settledByYouMinor: 0,
        );
      }
    }

    // 1. Process Shared Expenses
    for (final expense in sharedExpenses) {
      final payerUid = expense.paidByUid;

      if (payerUid == currentUserUid) {
        // Current user paid upfront for everyone.
        // Every other participant owes current user their assigned share.
        for (final p in expense.participants) {
          if (p.userId == currentUserUid) continue;
          ensureParticipant(p.userId, p.displayName, p.photoUrl);

          final current = participantMap[p.userId]!;
          participantMap[p.userId] = (
            name: current.name,
            photoUrl: current.photoUrl ?? p.photoUrl,
            theyOweYouMinor: current.theyOweYouMinor + p.assignedInMinorUnits,
            youOweThemMinor: current.youOweThemMinor,
            settledToYouMinor: current.settledToYouMinor,
            settledByYouMinor: current.settledByYouMinor,
          );
        }
      } else {
        // Someone else paid upfront.
        // Did current user participate? If so, current user owes payer their share.
        final myShare = expense.getShareForUser(currentUserUid);
        if (myShare != null && myShare.assignedAmount > 0) {
          ensureParticipant(payerUid, expense.paidByName, null);

          final current = participantMap[payerUid]!;
          participantMap[payerUid] = (
            name: current.name,
            photoUrl: current.photoUrl,
            theyOweYouMinor: current.theyOweYouMinor,
            youOweThemMinor:
                current.youOweThemMinor + myShare.assignedInMinorUnits,
            settledToYouMinor: current.settledToYouMinor,
            settledByYouMinor: current.settledByYouMinor,
          );
        }
      }
    }

    // 2. Process Settlements
    for (final settlement in settlements) {
      final amtMinor = settlement.amountInMinorUnits;

      if (settlement.payerUid == currentUserUid) {
        // Current user paid payee (settled an outstanding debt to payee)
        ensureParticipant(settlement.payeeUid, settlement.payeeName, null);
        final current = participantMap[settlement.payeeUid]!;
        participantMap[settlement.payeeUid] = (
          name: current.name,
          photoUrl: current.photoUrl,
          theyOweYouMinor: current.theyOweYouMinor,
          youOweThemMinor: current.youOweThemMinor,
          settledToYouMinor: current.settledToYouMinor,
          settledByYouMinor: current.settledByYouMinor + amtMinor,
        );
      } else if (settlement.payeeUid == currentUserUid) {
        // Another member paid current user (settled their debt to user)
        ensureParticipant(settlement.payerUid, settlement.payerName, null);
        final current = participantMap[settlement.payerUid]!;
        participantMap[settlement.payerUid] = (
          name: current.name,
          photoUrl: current.photoUrl,
          theyOweYouMinor: current.theyOweYouMinor,
          youOweThemMinor: current.youOweThemMinor,
          settledToYouMinor: current.settledToYouMinor + amtMinor,
          settledByYouMinor: current.settledByYouMinor,
        );
      }
    }

    // 3. Convert to ParticipantBalance objects
    final balances = <ParticipantBalance>[];
    for (final entry in participantMap.entries) {
      final val = entry.value;

      // Net they owe you = what they owed you minus what they settled to you
      final rawTheyOwe = val.theyOweYouMinor - val.settledToYouMinor;
      // Net you owe them = what you owed them minus what you settled to them
      final rawYouOwe = val.youOweThemMinor - val.settledByYouMinor;

      double finalTheyOwe = 0.0;
      double finalYouOwe = 0.0;

      final netMinor = rawTheyOwe - rawYouOwe;
      if (netMinor > 0) {
        finalTheyOwe = netMinor / 100.0;
      } else if (netMinor < 0) {
        finalYouOwe = (-netMinor) / 100.0;
      }

      balances.add(ParticipantBalance(
        participantUid: entry.key,
        displayName: val.name,
        photoUrl: val.photoUrl,
        amountTheyOweYou: finalTheyOwe,
        amountYouOweThem: finalYouOwe,
        totalSettled: (val.settledToYouMinor + val.settledByYouMinor) / 100.0,
      ));
    }

    // Sort by largest balance first
    balances.sort((a, b) => b.netBalance.abs().compareTo(a.netBalance.abs()));
    return balances;
  }
}
