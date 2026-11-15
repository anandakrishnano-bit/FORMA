import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Pre-defined standard and custom expense categories
class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isCustom;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  static const List<ExpenseCategory> defaultCategories = [
    ExpenseCategory(
      id: 'food_drinks',
      name: 'Food & drinks',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE98557), // terracotta/coral
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF54A0FF), // azure
    ),
    ExpenseCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFF27689), // coral pink
    ),
    ExpenseCategory(
      id: 'education',
      name: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFF8B80F9), // lavender
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie_creation_rounded,
      color: Color(0xFFFFC443), // golden yellow
    ),
    ExpenseCategory(
      id: 'subscriptions',
      name: 'Subscriptions',
      icon: Icons.credit_card_rounded,
      color: Color(0xFF88A95C), // sage
    ),
    ExpenseCategory(
      id: 'personal',
      name: 'Personal',
      icon: Icons.person_rounded,
      color: Color(0xFFFFAA2C), // amber
    ),
    ExpenseCategory(
      id: 'other',
      name: 'Other',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFFB8B7B5), // concrete grey
    ),
  ];

  static ExpenseCategory fromName(String name,
      {List<ExpenseCategory>? customCategories}) {
    final search = name.trim().toLowerCase();
    if (customCategories != null) {
      for (final cat in customCategories) {
        if (cat.name.toLowerCase() == search) return cat;
      }
    }
    for (final cat in defaultCategories) {
      if (cat.name.toLowerCase() == search || cat.id.toLowerCase() == search) {
        return cat;
      }
    }
    return ExpenseCategory(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      icon: Icons.label_rounded,
      color: const Color(0xFFFFBD35),
      isCustom: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'codePoint': icon.codePoint,
      'colorValue': color.toARGB32(),
      'isCustom': isCustom,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String? ?? 'custom',
      name: map['name'] as String? ?? 'Custom',
      icon: map['codePoint'] != null
          // ignore: non_const_argument_for_const_parameter
          ? IconData(map['codePoint'] as int, fontFamily: 'MaterialIcons')
          : Icons.label_rounded,
      color: map['colorValue'] != null
          ? Color(map['colorValue'] as int)
          : const Color(0xFFFFBD35),
      isCustom: map['isCustom'] as bool? ?? true,
    );
  }
}

/// Personal Expense Record (Completely Private to Authenticated User)
class PersonalExpense {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonalExpense({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.currency = '₹',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Minor-unit arithmetic representation (paise or cents) to avoid floating point errors
  int get amountInMinorUnits => (amount * 100).round();

  factory PersonalExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PersonalExpense(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'Other',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
      currency: data['currency'] as String? ?? '₹',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': (amount * 100).round() / 100, // Normalized to 2 decimal places
      'category': category,
      'date': Timestamp.fromDate(date),
      'note': note,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PersonalExpense copyWith({
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? currency,
    DateTime? updatedAt,
  }) {
    return PersonalExpense(
      id: id,
      userId: userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      currency: currency ?? this.currency,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Split methods for shared expenses
enum SplitMethod { equal, custom, percentage }

/// Participant share in a shared expense
class ParticipantShare {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final double assignedAmount;
  final double? percentage;
  final double amountPaid;

  const ParticipantShare({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.assignedAmount,
    this.percentage,
    this.amountPaid = 0.0,
  });

  /// Minor units representation
  int get assignedInMinorUnits => (assignedAmount * 100).round();
  int get paidInMinorUnits => (amountPaid * 100).round();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'assignedAmount': (assignedAmount * 100).round() / 100,
      'percentage': percentage,
      'amountPaid': (amountPaid * 100).round() / 100,
    };
  }

  factory ParticipantShare.fromMap(Map<String, dynamic> map) {
    return ParticipantShare(
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Participant',
      photoUrl:
          (map['photoUrl'] ?? map['photoURL'] ?? map['avatarUrl']) as String?,
      assignedAmount: (map['assignedAmount'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble(),
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ParticipantShare copyWith({
    double? assignedAmount,
    double? percentage,
    double? amountPaid,
  }) {
    return ParticipantShare(
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
      assignedAmount: assignedAmount ?? this.assignedAmount,
      percentage: percentage ?? this.percentage,
      amountPaid: amountPaid ?? this.amountPaid,
    );
  }
}

/// Shared Expense Record
class SharedExpense {
  final String id;
  final String title;
  final double totalAmount;
  final String currency;
  final String paidByUid;
  final String paidByName;
  final DateTime date;
  final String? note;
  final List<ParticipantShare> participants;
  final SplitMethod splitMethod;
  final String createdBy;
  final String? receiptUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SharedExpense({
    required this.id,
    required this.title,
    required this.totalAmount,
    this.currency = '₹',
    required this.paidByUid,
    required this.paidByName,
    required this.date,
    this.note,
    required this.participants,
    required this.splitMethod,
    required this.createdBy,
    this.receiptUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalInMinorUnits => (totalAmount * 100).round();

  List<String> get participantUids =>
      participants.map((p) => p.userId).toList();

  ParticipantShare? getShareForUser(String uid) {
    try {
      return participants.firstWhere((p) => p.userId == uid);
    } catch (_) {
      return null;
    }
  }

  factory SharedExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final splitMethodStr = data['splitMethod'] as String? ?? 'equal';
    final split = SplitMethod.values.firstWhere(
      (e) => e.name == splitMethodStr,
      orElse: () => SplitMethod.equal,
    );

    final rawParticipants = (data['participants'] as List<dynamic>?) ?? [];
    final participantsList = rawParticipants
        .map((p) => ParticipantShare.fromMap(p as Map<String, dynamic>))
        .toList();

    return SharedExpense(
      id: doc.id,
      title: data['title'] as String? ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? '₹',
      paidByUid: data['paidByUid'] as String? ?? '',
      paidByName: data['paidByName'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
      participants: participantsList,
      splitMethod: split,
      createdBy: data['createdBy'] as String? ?? '',
      receiptUrl: data['receiptUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'totalAmount': (totalAmount * 100).round() / 100,
      'currency': currency,
      'paidByUid': paidByUid,
      'paidByName': paidByName,
      'date': Timestamp.fromDate(date),
      'note': note,
      'participantUids': participantUids,
      'participants': participants.map((p) => p.toMap()).toList(),
      'splitMethod': splitMethod.name,
      'createdBy': createdBy,
      'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SharedExpense copyWith({
    String? title,
    double? totalAmount,
    String? currency,
    String? paidByUid,
    String? paidByName,
    DateTime? date,
    String? note,
    List<ParticipantShare>? participants,
    SplitMethod? splitMethod,
    String? receiptUrl,
    DateTime? updatedAt,
  }) {
    return SharedExpense(
      id: id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      paidByUid: paidByUid ?? this.paidByUid,
      paidByName: paidByName ?? this.paidByName,
      date: date ?? this.date,
      note: note ?? this.note,
      participants: participants ?? this.participants,
      splitMethod: splitMethod ?? this.splitMethod,
      createdBy: createdBy,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Recorded Settlement Record (Proof of Manual Settle-Up)
class ExpenseSettlement {
  final String id;
  final String payerUid;
  final String payerName;
  final String payeeUid;
  final String payeeName;
  final double amount;
  final String currency;
  final String? note;
  final DateTime paymentDate;
  final DateTime createdAt;

  const ExpenseSettlement({
    required this.id,
    required this.payerUid,
    required this.payerName,
    required this.payeeUid,
    required this.payeeName,
    required this.amount,
    this.currency = '₹',
    this.note,
    required this.paymentDate,
    required this.createdAt,
  });

  int get amountInMinorUnits => (amount * 100).round();

  factory ExpenseSettlement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExpenseSettlement(
      id: doc.id,
      payerUid: data['payerUid'] as String? ?? '',
      payerName: data['payerName'] as String? ?? '',
      payeeUid: data['payeeUid'] as String? ?? '',
      payeeName: data['payeeName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? '₹',
      note: data['note'] as String?,
      paymentDate:
          (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'payerUid': payerUid,
      'payerName': payerName,
      'payeeUid': payeeUid,
      'payeeName': payeeName,
      'amount': (amount * 100).round() / 100,
      'currency': currency,
      'note': note,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Participant Balance Summary for Ledger Calculations
class ParticipantBalance {
  final String participantUid;
  final String displayName;
  final String? photoUrl;
  final double amountTheyOweYou;
  final double amountYouOweThem;
  final double totalSettled;

  const ParticipantBalance({
    required this.participantUid,
    required this.displayName,
    this.photoUrl,
    this.amountTheyOweYou = 0.0,
    this.amountYouOweThem = 0.0,
    this.totalSettled = 0.0,
  });

  /// Net balance from perspective of current user:
  /// Positive: They owe you money
  /// Negative: You owe them money
  /// Zero: Settled
  double get netBalance => (amountTheyOweYou - amountYouOweThem);

  bool get isSettled => netBalance.abs() < 0.01;
  bool get youAreOwed => netBalance > 0.01;
  bool get youOwe => netBalance < -0.01;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PERSONAL BUDGET PLANNER & FIXED EXPENSES
/// ═══════════════════════════════════════════════════════════════════════════

/// Represents an active or planned budget period
class BudgetPlan {
  final String id;
  final String userId;
  final double totalBudget;
  final DateTime startDate;
  final DateTime endDate;
  final String currency;
  final String? description;
  final bool
      isFlexibleMode; // false = Daily Plan, true = Flexible / Cumulative Plan
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetPlan({
    required this.id,
    required this.userId,
    required this.totalBudget,
    required this.startDate,
    required this.endDate,
    this.currency = '₹',
    this.description,
    this.isFlexibleMode = false,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalBudgetCents => (totalBudget * 100).round();

  int get totalDays {
    final diff = endDate.difference(startDate).inDays + 1;
    return diff > 0 ? diff : 1;
  }

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (today.isAfter(end)) return 0;
    return end.difference(today).inDays + 1;
  }

  bool get isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !today.isBefore(start) && !today.isAfter(end);
  }

  factory BudgetPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BudgetPlan(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      totalBudget: (data['totalBudget'] as num?)?.toDouble() ?? 0.0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      currency: data['currency'] as String? ?? '₹',
      description: data['description'] as String?,
      isFlexibleMode: data['isFlexibleMode'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalBudget': (totalBudget * 100).round() / 100,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'currency': currency,
      'description': description,
      'isFlexibleMode': isFlexibleMode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BudgetPlan copyWith({
    double? totalBudget,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    String? description,
    bool? isFlexibleMode,
  }) {
    return BudgetPlan(
      id: id,
      userId: userId,
      totalBudget: totalBudget ?? this.totalBudget,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      isFlexibleMode: isFlexibleMode ?? this.isFlexibleMode,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Represents a recurring or one-time fixed commitment (e.g. rent, travel pass, subscriptions)
class FixedExpense {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String category;
  final DateTime dueDate;
  final String
      frequency; // 'daily', 'weekdays', 'weekly', 'monthly', 'one-time', 'custom'
  final String? note;
  final bool isPaid;
  final bool isPaused;
  final bool
      isObligation; // true = Mandatory bill/obligation (reserved upfront); false = Flexible recurring spending habit (eggs, groceries)
  final DateTime createdAt;
  final DateTime updatedAt;

  const FixedExpense({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.category,
    required this.dueDate,
    this.frequency = 'monthly',
    this.note,
    this.isPaid = false,
    this.isPaused = false,
    this.isObligation = true,
    required this.createdAt,
    required this.updatedAt,
  });

  int get amountCents => (amount * 100).round();

  factory FixedExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FixedExpense(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? 'Fixed Expense',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'Subscriptions',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      frequency: data['frequency'] as String? ?? 'monthly',
      note: data['note'] as String?,
      isPaid: data['isPaid'] as bool? ?? false,
      isPaused: data['isPaused'] as bool? ?? false,
      isObligation: data['isObligation'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'amount': (amount * 100).round() / 100,
      'category': category,
      'dueDate': Timestamp.fromDate(dueDate),
      'frequency': frequency,
      'note': note,
      'isPaid': isPaid,
      'isPaused': isPaused,
      'isObligation': isObligation,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FixedExpense copyWith({
    String? name,
    double? amount,
    String? category,
    DateTime? dueDate,
    String? frequency,
    String? note,
    bool? isPaid,
    bool? isPaused,
    bool? isObligation,
  }) {
    return FixedExpense(
      id: id,
      userId: userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      note: note ?? this.note,
      isPaid: isPaid ?? this.isPaid,
      isPaused: isPaused ?? this.isPaused,
      isObligation: isObligation ?? this.isObligation,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Comprehensive Calculated Budget Summary
class BudgetPlannerSummary {
  final BudgetPlan? plan;
  final double totalBudget;
  final double variableSpent;
  final double totalFixedExpenses;
  final double paidFixedExpenses;
  final double upcomingFixedReserved;
  final double remainingSpendableBudget;
  final double suggestedDailyAllowance;
  final double todayActualSpent;
  final double todayRemainingAllowance;
  final int daysRemaining;
  final int totalDays;
  final bool isOverBudget;
  final List<String> suggestions;
  final double expectedRecurringHabitsTotal;
  final double expectedDailyHabitsAllocation;

  const BudgetPlannerSummary({
    this.plan,
    required this.totalBudget,
    required this.variableSpent,
    required this.totalFixedExpenses,
    required this.paidFixedExpenses,
    required this.upcomingFixedReserved,
    required this.remainingSpendableBudget,
    required this.suggestedDailyAllowance,
    required this.todayActualSpent,
    required this.todayRemainingAllowance,
    required this.daysRemaining,
    required this.totalDays,
    required this.isOverBudget,
    required this.suggestions,
    this.expectedRecurringHabitsTotal = 0.0,
    this.expectedDailyHabitsAllocation = 0.0,
  });

  static const empty = BudgetPlannerSummary(
    plan: null,
    totalBudget: 0.0,
    variableSpent: 0.0,
    totalFixedExpenses: 0.0,
    paidFixedExpenses: 0.0,
    upcomingFixedReserved: 0.0,
    remainingSpendableBudget: 0.0,
    suggestedDailyAllowance: 0.0,
    todayActualSpent: 0.0,
    todayRemainingAllowance: 0.0,
    daysRemaining: 0,
    totalDays: 0,
    isOverBudget: false,
    suggestions: [],
    expectedRecurringHabitsTotal: 0.0,
    expectedDailyHabitsAllocation: 0.0,
  );
}
