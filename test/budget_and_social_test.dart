import 'package:flutter_test/flutter_test.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/models/friends_model.dart';
import 'package:forma/data/models/nutrition_model.dart';
import 'package:forma/data/repositories/expense_repository.dart';

void main() {
  group('Personal Budget Planner Arithmetic Tests', () {
    test('Daily Allowance minor unit derivation across active period', () {
      final now = DateTime.now();
      final plan = BudgetPlan(
        id: 'plan_test',
        userId: 'user_test',
        totalBudget: 15000.0,
        currency: '₹',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        isFlexibleMode: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(plan.totalBudget, equals(15000.0));
      expect(plan.daysRemaining, greaterThanOrEqualTo(29));
      expect(plan.isActive, isTrue);

      // Fixed expense reservation
      final fixedSub = FixedExpense(
        id: 'fixed_1',
        userId: 'user_test',
        name: 'Gym Membership',
        amount: 2000.0,
        category: 'Personal',
        dueDate: now.add(const Duration(days: 10)),
        frequency: 'monthly',
        isPaid: false,
        createdAt: now,
        updatedAt: now,
      );

      final summary = ExpenseRepository.computeBudgetSummary(
        plan: plan,
        expenses: [],
        fixedExpenses: [fixedSub],
      );

      expect(summary.totalBudget, equals(15000.0));
      expect(summary.totalFixedExpenses, equals(2000.0));
      expect(summary.upcomingFixedReserved, equals(2000.0));
      expect(summary.remainingSpendableBudget, equals(13000.0));
      expect(summary.suggestedDailyAllowance, greaterThan(350.0));
    });
  });

  group('Food Catalogue Search & Branded Distinction Tests', () {
    test('General whole foods vs branded products tagging', () {
      const wholeRice = FoodItem(
        id: 'f_rice',
        name: 'Steamed White Rice',
        category: 'Rice and Grains',
        calories: 130,
        protein: 2.7,
        carbs: 28.2,
        fat: 0.3,
        isBranded: false,
      );

      const brandedYogurt = FoodItem(
        id: 'f_epigamia',
        name: 'Epigamia Greek Yogurt',
        category: 'Dairy',
        calories: 85,
        protein: 6.0,
        carbs: 6.0,
        fat: 4.0,
        isBranded: true,
        brandName: 'Epigamia',
      );

      expect(wholeRice.isBranded, isFalse);
      expect(wholeRice.brandName, isNull);

      expect(brandedYogurt.isBranded, isTrue);
      expect(brandedYogurt.brandName, equals('Epigamia'));

      final list = [brandedYogurt, wholeRice];
      // Sorting priority: whole unbranded foods first
      list.sort((a, b) {
        if (a.isBranded != b.isBranded) {
          return a.isBranded ? 1 : -1;
        }
        return a.name.compareTo(b.name);
      });

      expect(list.first.id, equals('f_rice'));
      expect(list.last.id, equals('f_epigamia'));
    });
  });

  group('Friends & Social Lifecycle Tests', () {
    test('FriendRequest serialization and status handling', () {
      final req = FriendRequest(
        id: 'userA_userB',
        senderId: 'userA',
        senderName: 'Anand',
        senderUsername: 'anand_fit',
        receiverId: 'userB',
        receiverName: 'Vikram',
        receiverUsername: 'vikram_lift',
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(req.status, equals(FriendRequestStatus.pending));
      final map = req.toMap();
      expect(map['status'], equals('pending'));
      expect(map['senderUsername'], equals('anand_fit'));
    });

    test('SocialGroup creation and role assignment', () {
      final group = SocialGroup(
        id: 'grp_123',
        name: 'Morning Crew',
        description: '5am lifting squad',
        ownerId: 'user_owner',
        adminIds: ['user_owner'],
        memberIds: ['user_owner', 'user_member2'],
        joinCode: 'GRP-LIFT5A',
        createdAt: DateTime.now(),
      );

      expect(group.memberIds.length, equals(2));
      expect(group.adminIds.contains('user_owner'), isTrue);
      expect(group.isPrivate, isTrue);
    });
  });
}
