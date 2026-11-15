import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma/data/models/nutrition_model.dart';
import 'package:forma/data/sources/food_seed_data.dart';
import 'package:forma/data/repositories/habit_repository.dart';

class NutritionRepository {
  final Ref? ref;
  static final List<FoodItem> _customFoods = [];
  static final List<MealEntry> _cachedEntries = [];
  static bool _hasLoadedFromPrefs = false;

  NutritionRepository([this.ref]);

  String _getTodayKey() {
    final now = DateTime.now();
    return 'daily_meals_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _ensureLoaded() async {
    if (_hasLoadedFromPrefs) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getTodayKey();
      final raw = prefs.getStringList(key);
      if (raw != null && raw.isNotEmpty) {
        _cachedEntries.clear();
        for (final item in raw) {
          final map = json.decode(item) as Map<String, dynamic>;
          _cachedEntries.add(MealEntry.fromMap(map));
        }
      }
      _hasLoadedFromPrefs = true;
    } catch (_) {}
  }

  Future<List<MealEntry>> getTodayMeals() async {
    await _ensureLoaded();
    final now = DateTime.now();
    return _cachedEntries
        .where((m) =>
            m.date.year == now.year &&
            m.date.month == now.month &&
            m.date.day == now.day)
        .toList();
  }

  Future<List<FoodItem>> searchFoods(
    String query, {
    String? category,
    bool? isBranded,
  }) async {
    final all = [...FoodSeedData.foods, ..._customFoods];
    var list = all;
    if (category != null && category != 'All' && category.isNotEmpty) {
      list = list.where((f) => f.category == category).toList();
    }
    if (isBranded != null) {
      list = list.where((f) => f.isBranded == isBranded).toList();
    }
    if (query.trim().isNotEmpty) {
      final lower = query.toLowerCase();
      list = list.where((f) {
        final matchesName = f.name.toLowerCase().contains(lower);
        final matchesCategory = f.category.toLowerCase().contains(lower);
        final matchesBrand =
            f.brandName != null && f.brandName!.toLowerCase().contains(lower);
        return matchesName || matchesCategory || matchesBrand;
      }).toList();

      // Prioritize generic whole foods (isBranded == false) over branded products when searching generic terms
      list.sort((a, b) {
        if (a.isBranded != b.isBranded) {
          return a.isBranded ? 1 : -1; // unbranded whole foods come first
        }
        return a.name.compareTo(b.name);
      });
    }
    return list;
  }

  Future<List<FoodItem>> searchFood(String query) async {
    return searchFoods(query);
  }

  Future<void> logMeal(MealEntry meal) async {
    await _ensureLoaded();
    _cachedEntries.add(meal);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getTodayKey();
      final rawList =
          _cachedEntries.map((m) => json.encode(m.toMap())).toList();
      await prefs.setStringList(key, rawList);

      if (ref != null) {
        final totalCalories =
            _cachedEntries.fold<double>(0, (s, m) => s + m.totalCalories);
        if (totalCalories >= 1500) {
          ref!
              .read(habitRepositoryProvider)
              .toggleHabit('h_diet', DateTime.now());
        }
        final totalProtein =
            _cachedEntries.fold<double>(0, (s, m) => s + m.totalProtein);
        if (totalProtein >= 80) {
          ref!
              .read(habitRepositoryProvider)
              .toggleHabit('h_protein', DateTime.now());
        }
      }
    } catch (_) {}
  }

  Future<void> addCustomFood(FoodItem food) async {
    _customFoods.add(food);
  }

  // ──────────────── Custom Portions (users/{uid}/customPortions) ────────────

  Future<void> saveCustomPortion(CustomPortion portion) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('customPortions')
          .add(portion.toMap());
    } catch (_) {}
  }

  Future<List<CustomPortion>> getCustomPortions({String? foodId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      var query = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('customPortions')
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      final portions =
          snapshot.docs.map((doc) => CustomPortion.fromFirestore(doc)).toList();
      if (foodId != null && foodId.isNotEmpty) {
        return portions.where((p) => p.foodId == foodId).toList();
      }
      return portions;
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteCustomPortion(String portionId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('customPortions')
          .doc(portionId)
          .delete();
    } catch (_) {}
  }
}

final customPortionsProvider =
    FutureProvider.family<List<CustomPortion>, String?>((ref, foodId) async {
  return ref
      .watch(nutritionRepositoryProvider)
      .getCustomPortions(foodId: foodId);
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref);
});

final todayMealsProvider = FutureProvider<List<MealEntry>>((ref) async {
  return ref.watch(nutritionRepositoryProvider).getTodayMeals();
});

final foodSearchProvider =
    FutureProvider.family<List<FoodItem>, String>((ref, query) async {
  return ref.watch(nutritionRepositoryProvider).searchFood(query);
});
