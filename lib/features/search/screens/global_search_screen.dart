import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/workout_model.dart';
import 'package:forma/data/models/workout_session_model.dart';
import 'package:forma/data/models/expense_model.dart';
import 'package:forma/data/sources/exercise_seed_data.dart';
import 'package:forma/data/sources/food_seed_data.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:forma/data/repositories/habit_repository.dart';
import 'package:forma/data/repositories/expense_repository.dart';

enum SearchCategory {
  all('All'),
  exercises('Exercises'),
  nutrition('Foods & Recipes'),
  workouts('Workouts'),
  habits('Habits'),
  expenses('Expenses'),
  friends('Friends');

  final String label;
  const SearchCategory(this.label);
}

class SearchResultItem {
  final String id;
  final String title;
  final String subtitle;
  final String categoryLabel;
  final Color categoryColor;
  final IconData icon;
  final VoidCallback onTap;

  SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categoryLabel,
    required this.categoryColor,
    required this.icon,
    required this.onTap,
  });
}

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  SearchCategory _selectedCategory = SearchCategory.all;

  List<String> _recentSearches = [];
  Timer? _debounceTimer;
  String _currentQuery = '';

  static const String _prefRecentKey = 'forma_global_recent_searches';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefRecentKey) ?? [];
      if (mounted) setState(() => _recentSearches = list);
    } catch (_) {}
  }

  Future<void> _saveRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = List<String>.from(_recentSearches);
      list.remove(clean);
      list.insert(0, clean);
      if (list.length > 10) list.removeLast();
      await prefs.setStringList(_prefRecentKey, list);
      if (mounted) setState(() => _recentSearches = list);
    } catch (_) {}
  }

  Future<void> _removeRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = List<String>.from(_recentSearches)..remove(query);
      await prefs.setStringList(_prefRecentKey, list);
      if (mounted) setState(() => _recentSearches = list);
    } catch (_) {}
  }

  Future<void> _clearAllRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefRecentKey);
      if (mounted) setState(() => _recentSearches = []);
    } catch (_) {}
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      final query = _searchController.text.trim();
      if (query != _currentQuery) {
        setState(() => _currentQuery = query);
        if (query.isNotEmpty) {
          _saveRecentSearch(query);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final workoutsAsync = ref.watch(workoutTemplatesProvider);
    final workoutHistoryAsync = ref.watch(workoutHistoryProvider);
    final habitsAsync = ref.watch(habitsListProvider);
    final expensesAsync = ref.watch(personalExpensesStreamProvider);

    final templates = workoutsAsync.valueOrNull ?? [];
    final history = workoutHistoryAsync.valueOrNull ?? [];
    final habits = habitsAsync.valueOrNull ?? [];
    final expenses = expensesAsync.valueOrNull ?? [];

    final results = _computeResults(
      query: _currentQuery.toLowerCase(),
      category: _selectedCategory,
      templates: templates,
      history: history,
      habits: habits,
      expenses: expenses,
    );

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Home',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            'Search FORMA',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search Input Field
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? FormaColors.charcoal : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white12
                          : FormaColors.divider.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText:
                          'Search exercises, food, workouts, habits, expenses...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: FormaColors.concreteGrey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _currentQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              // Category Filter Pills
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: SearchCategory.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = SearchCategory.values[index];
                    final isSelected = _selectedCategory == cat;
                    return FormaBounceable(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FormaColors.goldenYellow
                              : (isDark
                                  ? FormaColors.charcoal
                                  : const Color(0xFFF0EDE5)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? Colors.white10 : Colors.black12),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? FormaColors.charcoal
                                  : (isDark
                                      ? FormaColors.darkPrimaryText
                                      : FormaColors.lightPrimaryText),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Results or Recent Searches
              Expanded(
                child: _currentQuery.isEmpty
                    ? _buildRecentSearches(isDark)
                    : _buildSearchResults(results, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches(bool isDark) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.saved_search_rounded,
                size: 48, color: FormaColors.concreteGrey),
            const SizedBox(height: 12),
            Text(
              'Search Anything in FORMA',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? FormaColors.darkPrimaryText
                    : FormaColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Search across exercises, nutrition, workouts, habits, expenses and friends.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
            ),
            TextButton(
              onPressed: _clearAllRecent,
              child: const Text(
                'Clear All',
                style: TextStyle(
                    fontSize: 12,
                    color: FormaColors.coralPink,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        ..._recentSearches.map((query) => ListTile(
              leading: const Icon(Icons.history_rounded,
                  size: 20, color: FormaColors.concreteGrey),
              title: Text(query,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: () => _removeRecentSearch(query),
              ),
              onTap: () {
                _searchController.text = query;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: query.length),
                );
              },
            )),
      ],
    );
  }

  Widget _buildSearchResults(List<SearchResultItem> results, bool isDark) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: FormaColors.concreteGrey),
            const SizedBox(height: 12),
            Text(
              'No matches for "$_currentQuery"',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? FormaColors.darkPrimaryText
                    : FormaColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your search terms or selecting "All" categories.',
              style: TextStyle(
                fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = results[index];
        return FormaBounceable(
          onTap: () {
            HapticFeedback.lightImpact();
            item.onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? FormaColors.charcoal : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : FormaColors.divider.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, size: 20, color: item.categoryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.categoryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.categoryLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: item.categoryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12,
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
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: FormaColors.concreteGrey),
              ],
            ),
          ),
        );
      },
    );
  }

  List<SearchResultItem> _computeResults({
    required String query,
    required SearchCategory category,
    required List<WorkoutModel> templates,
    required List<WorkoutSessionModel> history,
    required List<dynamic> habits,
    required List<PersonalExpense> expenses,
  }) {
    if (query.isEmpty) return [];

    final results = <SearchResultItem>[];

    // 1. Exercises
    if (category == SearchCategory.all ||
        category == SearchCategory.exercises) {
      final matchingExercises = ExerciseSeedData.exercises.where((e) {
        return e.name.toLowerCase().contains(query) ||
            e.primaryMuscle.toLowerCase().contains(query) ||
            e.equipment.toLowerCase().contains(query);
      }).take(10);

      for (final ex in matchingExercises) {
        results.add(
          SearchResultItem(
            id: 'ex_${ex.id}',
            title: ex.name,
            subtitle: '${ex.primaryMuscle} • ${ex.equipment}',
            categoryLabel: 'EXERCISE',
            categoryColor: FormaColors.coralPink,
            icon: Icons.fitness_center_rounded,
            onTap: () {
              context.push('/workout/exercise-detail', extra: ex);
            },
          ),
        );
      }
    }

    // 2. Nutrition & Foods
    if (category == SearchCategory.all ||
        category == SearchCategory.nutrition) {
      final matchingFoods = FoodSeedData.foods.where((f) {
        return f.name.toLowerCase().contains(query) ||
            f.category.toLowerCase().contains(query);
      }).take(10);

      for (final food in matchingFoods) {
        results.add(
          SearchResultItem(
            id: 'food_${food.id}',
            title: food.name,
            subtitle:
                '${food.calories.toInt()} kcal • P: ${food.protein.toInt()}g • C: ${food.carbs.toInt()}g • F: ${food.fat.toInt()}g',
            categoryLabel: 'FOOD',
            categoryColor: FormaColors.goldenYellow,
            icon: Icons.restaurant_rounded,
            onTap: () {
              context.go('/nutrition');
            },
          ),
        );
      }
    }

    // 3. Workouts (Templates & History)
    if (category == SearchCategory.all || category == SearchCategory.workouts) {
      for (final tmpl
          in templates.where((t) => t.name.toLowerCase().contains(query))) {
        results.add(
          SearchResultItem(
            id: 'workout_${tmpl.id}',
            title: tmpl.name,
            subtitle:
                'Workout Plan • ${tmpl.exercises.length} exercises • ${tmpl.estimatedDurationMinutes} min',
            categoryLabel: 'WORKOUT',
            categoryColor: const Color(0xFF6B7280),
            icon: Icons.fitness_center_rounded,
            onTap: () {
              context.go('/workout');
            },
          ),
        );
      }

      for (final sess in history
          .where((s) => s.workoutName.toLowerCase().contains(query))
          .take(5)) {
        results.add(
          SearchResultItem(
            id: 'session_${sess.id}',
            title: sess.workoutName,
            subtitle:
                'Logged session • ${sess.exercises.length} exercises • ${sess.totalVolume.toInt()} kg volume',
            categoryLabel: 'WORKOUT LOG',
            categoryColor: FormaColors.coralPink,
            icon: Icons.history_rounded,
            onTap: () {
              context.go('/workout');
            },
          ),
        );
      }
    }

    // 4. Habits
    if (category == SearchCategory.all || category == SearchCategory.habits) {
      for (final h in habits) {
        final title = h.title;
        final categoryName = h.category;
        if (query.isEmpty ||
            title.toLowerCase().contains(query) ||
            categoryName.toLowerCase().contains(query)) {
          results.add(
            SearchResultItem(
              id: 'habit_${h.id}',
              title: title,
              subtitle: 'Habit • $categoryName',
              categoryLabel: 'HABIT',
              categoryColor: FormaColors.secondaryAccent,
              icon: Icons.check_circle_outline_rounded,
              onTap: () {
                context.go('/habits');
              },
            ),
          );
        }
      }
    }

    // 5. Expenses
    if (category == SearchCategory.all || category == SearchCategory.expenses) {
      for (final exp in expenses
          .where((e) =>
              e.title.toLowerCase().contains(query) ||
              e.category.toLowerCase().contains(query) ||
              (e.note?.toLowerCase().contains(query) ?? false))
          .take(10)) {
        results.add(
          SearchResultItem(
            id: 'expense_${exp.id}',
            title: exp.title,
            subtitle: '₹${exp.amount.toStringAsFixed(0)} • ${exp.category}',
            categoryLabel: 'EXPENSE',
            categoryColor: FormaColors.semanticSteps,
            icon: Icons.account_balance_wallet_rounded,
            onTap: () {
              context.push('/expenses/detail', extra: exp);
            },
          ),
        );
      }
    }

    return results;
  }
}
