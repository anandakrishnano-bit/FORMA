import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/services/discovery_service.dart';
import 'package:forma/data/models/exercise_model.dart';
import 'package:forma/data/models/nutrition_model.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:forma/data/repositories/nutrition_repository.dart';
import 'package:forma/data/sources/exercise_seed_data.dart';
import 'package:forma/data/sources/food_seed_data.dart';

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  return DiscoveryService(geminiApiKey: apiKey.isNotEmpty ? apiKey : null);
});

enum DiscoveryStatus { idle, searching, found, notFound, saved }

class SearchDiscoveryState<T> {
  final DiscoveryStatus status;
  final List<T> internalResults;
  final List<T> discoveredResults;
  final String statusMessage;
  final String currentQuery;

  const SearchDiscoveryState({
    this.status = DiscoveryStatus.idle,
    this.internalResults = const [],
    this.discoveredResults = const [],
    this.statusMessage = '',
    this.currentQuery = '',
  });

  SearchDiscoveryState<T> copyWith({
    DiscoveryStatus? status,
    List<T>? internalResults,
    List<T>? discoveredResults,
    String? statusMessage,
    String? currentQuery,
  }) {
    return SearchDiscoveryState<T>(
      status: status ?? this.status,
      internalResults: internalResults ?? this.internalResults,
      discoveredResults: discoveredResults ?? this.discoveredResults,
      statusMessage: statusMessage ?? this.statusMessage,
      currentQuery: currentQuery ?? this.currentQuery,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// EXERCISE DISCOVERY CONTROLLER (Unified Local + Online/AI Search)
// ═════════════════════════════════════════════════════════════════════════

class ExerciseDiscoveryNotifier
    extends StateNotifier<SearchDiscoveryState<ExerciseModel>> {
  final WorkoutRepository _workoutRepo;
  final DiscoveryService _discoveryService;

  ExerciseDiscoveryNotifier(this._workoutRepo, this._discoveryService)
      : super(const SearchDiscoveryState());

  /// Instant local filter as the user types
  Future<void> search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      state = const SearchDiscoveryState();
      return;
    }

    final allInternal = await _workoutRepo.getExercises();
    final internalMatches = allInternal.where((ex) {
      return ex.name.toLowerCase().contains(cleanQuery) ||
          ex.primaryMuscle.toLowerCase().contains(cleanQuery) ||
          ex.equipment.toLowerCase().contains(cleanQuery);
    }).toList();

    state = state.copyWith(
      status: DiscoveryStatus.found,
      internalResults: internalMatches,
      discoveredResults: const [],
      currentQuery: query,
      statusMessage: '',
    );
  }

  /// Explicit or fallback online AI search
  Future<void> triggerOnlineSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    state = state.copyWith(
      status: DiscoveryStatus.searching,
      currentQuery: cleanQuery,
      statusMessage: 'Searching sports science & biomechanics databases...',
    );

    final discovered = await _discoveryService.discoverExercises(cleanQuery);

    if (discovered.isNotEmpty) {
      // Auto-cache discovered exercises into seed so they are permanently reusable
      for (final ex in discovered) {
        if (!ExerciseSeedData.exercises
            .any((e) => e.name.toLowerCase() == ex.name.toLowerCase())) {
          ExerciseSeedData.exercises.add(ex);
        }
      }
      state = state.copyWith(
        status: DiscoveryStatus.found,
        discoveredResults: discovered,
        statusMessage: '',
      );
    } else {
      state = state.copyWith(
        status: DiscoveryStatus.notFound,
        statusMessage:
            'No online matches found. You can log a custom exercise.',
      );
    }
  }

  Future<void> approveAndSaveExercise(ExerciseModel exercise) async {
    if (!ExerciseSeedData.exercises.any((e) => e.id == exercise.id)) {
      ExerciseSeedData.exercises.add(exercise);
    }
    state = state.copyWith(
      status: DiscoveryStatus.saved,
      internalResults: [exercise],
      statusMessage: 'Added to your permanent exercise library',
    );
  }

  void clear() {
    state = const SearchDiscoveryState();
  }
}

final exerciseDiscoveryProvider = StateNotifierProvider<
    ExerciseDiscoveryNotifier, SearchDiscoveryState<ExerciseModel>>((ref) {
  return ExerciseDiscoveryNotifier(
    ref.watch(workoutRepositoryProvider),
    ref.watch(discoveryServiceProvider),
  );
});

// ═════════════════════════════════════════════════════════════════════════
// FOOD DISCOVERY CONTROLLER (Unified Local + Online/AI Search)
// ═════════════════════════════════════════════════════════════════════════

class FoodDiscoveryNotifier
    extends StateNotifier<SearchDiscoveryState<FoodItem>> {
  final NutritionRepository _nutritionRepo;
  final DiscoveryService _discoveryService;

  FoodDiscoveryNotifier(this._nutritionRepo, this._discoveryService)
      : super(const SearchDiscoveryState());

  /// Instant local filter as the user types
  Future<void> search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      state = const SearchDiscoveryState();
      return;
    }

    final internalMatches = await _nutritionRepo.searchFoods(cleanQuery);
    state = state.copyWith(
      status: DiscoveryStatus.found,
      internalResults: internalMatches,
      discoveredResults: const [],
      currentQuery: query,
      statusMessage: '',
    );
  }

  /// Explicit or fallback online AI search
  Future<void> triggerOnlineSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    state = state.copyWith(
      status: DiscoveryStatus.searching,
      currentQuery: cleanQuery,
      statusMessage: 'Searching food composition & nutritional databases...',
    );

    final discovered = await _discoveryService.discoverFoods(cleanQuery);

    if (discovered.isNotEmpty) {
      // Auto-cache discovered foods so they are permanently available
      for (final f in discovered) {
        if (!FoodSeedData.foods
            .any((food) => food.name.toLowerCase() == f.name.toLowerCase())) {
          FoodSeedData.foods.add(f);
        }
      }
      state = state.copyWith(
        status: DiscoveryStatus.found,
        discoveredResults: discovered,
        statusMessage: '',
      );
    } else {
      state = state.copyWith(
        status: DiscoveryStatus.notFound,
        statusMessage: 'No nutritional records found online.',
      );
    }
  }

  Future<void> approveAndSaveFood(FoodItem food) async {
    if (!FoodSeedData.foods.any((f) => f.id == food.id)) {
      FoodSeedData.foods.add(food);
    }
    state = state.copyWith(
      status: DiscoveryStatus.saved,
      internalResults: [food],
      statusMessage: 'Added to your permanent food database',
    );
  }

  void clear() {
    state = const SearchDiscoveryState();
  }
}

final foodDiscoveryProvider = StateNotifierProvider<FoodDiscoveryNotifier,
    SearchDiscoveryState<FoodItem>>((ref) {
  return FoodDiscoveryNotifier(
    ref.watch(nutritionRepositoryProvider),
    ref.watch(discoveryServiceProvider),
  );
});
