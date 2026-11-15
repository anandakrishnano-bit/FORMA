import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:forma/core/services/gemini_client_service.dart';
import 'package:forma/core/services/secure_storage_service.dart';
import 'package:forma/data/models/exercise_model.dart';
import 'package:forma/data/models/nutrition_model.dart';

/// Intelligent Discovery Service using:
/// 1. wger REST API (exercises)
/// 2. Open Food Facts (food & nutrition)
/// 3. Google Gemini using each user's individual key (loaded from Keystore)
/// 4. Verified Sports Science & Indian Nutrition dictionary fallback
class DiscoveryService {
  static const String _wgerBaseUrl = 'https://wger.de/api/v2';
  static const String _openFoodFactsUrl =
      'https://world.openfoodfacts.org/cgi/search.pl';
  final SecureStorageService _secureStorage = SecureStorageService();
  final String? geminiApiKey;

  DiscoveryService({this.geminiApiKey});

  // ═════════════════════════════════════════════════════════════════════════
  // EXERCISE DISCOVERY (wger API + User's Gemini Key + Factual Biomechanics)
  // ═════════════════════════════════════════════════════════════════════════

  Future<List<ExerciseModel>> discoverExercises(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    // 1. Try wger API with verified headers
    try {
      final uri = Uri.parse(
          '$_wgerBaseUrl/exercise/search/?term=${Uri.encodeComponent(query)}');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'FormaFitness/2.0 (Android; contact@forma.app)',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['suggestions'] as List<dynamic>? ?? [];

        if (suggestions.isNotEmpty) {
          final results = <ExerciseModel>[];
          for (final item in suggestions.take(6)) {
            final dataObj = item['data'] ?? {};
            final id =
                'wger_${dataObj['id'] ?? DateTime.now().millisecondsSinceEpoch}';
            final name = item['value'] ?? query;
            final category = dataObj['category'] ?? 'General';
            final image = dataObj['image'] != null
                ? 'https://wger.de${dataObj['image']}'
                : '';

            results.add(
              ExerciseModel(
                id: id,
                name: name,
                imageUrl: image,
                primaryMuscle: _mapMuscle(category),
                secondaryMuscles: const [],
                equipment: 'Gym Equipment',
                difficulty: 'Intermediate',
                instructions:
                    'Maintain rigid core posture and follow controlled tempo throughout $name.',
                category: category.toString().toLowerCase(),
              ),
            );
          }
          if (results.isNotEmpty) return results;
        }
      }
    } catch (_) {}

    // 2. Structured Discovery via User's Personal Gemini Key or Provided Key
    final effectiveKey =
        await _secureStorage.getUserGeminiKey() ?? geminiApiKey;
    if (effectiveKey != null && effectiveKey.isNotEmpty) {
      final geminiResult =
          await _discoverExerciseViaGemini(query, effectiveKey);
      if (geminiResult != null) {
        return [geminiResult];
      }
    }

    // 3. Factual Biomechanics Dictionary Fallback
    final fallback = _findFallbackExercises(clean);
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return [];
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FOOD DISCOVERY (Curated General Subcategories + Gemini AI + Clean Fallback)
  // ═════════════════════════════════════════════════════════════════════════

  Future<List<FoodItem>> discoverFoods(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    // 1. Priority 1: Check curated general foods with subcategories (e.g. pizza -> chicken, sausage, paneer, veg)
    final fallback = _findFallbackFoods(clean);
    if (fallback.isNotEmpty) {
      return fallback;
    }

    // 2. Priority 2: Structured Discovery via User's Personal Gemini Key or Provided Key
    final effectiveKey =
        await _secureStorage.getUserGeminiKey() ?? geminiApiKey;
    if (effectiveKey != null && effectiveKey.isNotEmpty) {
      final geminiFoods = await _discoverFoodViaGemini(query, effectiveKey);
      if (geminiFoods.isNotEmpty) {
        return geminiFoods;
      }
    }

    // 3. Priority 3: Generic search from Open Food Facts (filtering out commercial brand names)
    try {
      final uri = Uri.parse(
        '$_openFoodFactsUrl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=6',
      );
      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'FormaFitnessCompanion/2.0 (Android; contact@forma.app)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List<dynamic>? ?? [];

        if (products.isNotEmpty) {
          final results = <FoodItem>[];
          for (final prod in products) {
            String name =
                (prod['product_name'] ?? prod['generic_name'] ?? '').toString();
            if (name.trim().isEmpty) continue;

            // Clean up brand noise from title
            name = name
                .replaceAll(
                    RegExp(
                        r'^(Tesco|Nestle|Dr\.\s*Oetker|Kraft|Heinz|Great Value|Walmart)\s*',
                        caseSensitive: false),
                    '')
                .trim();
            if (name.isEmpty) name = prod['generic_name'] ?? query;

            final nutriments = prod['nutriments'] ?? {};
            final calories = (nutriments['energy-kcal_100g'] ??
                    nutriments['energy-kcal'] ??
                    0)
                .toDouble();
            final protein =
                (nutriments['proteins_100g'] ?? nutriments['proteins'] ?? 0)
                    .toDouble();
            final carbs = (nutriments['carbohydrates_100g'] ??
                    nutriments['carbohydrates'] ??
                    0)
                .toDouble();
            final fat =
                (nutriments['fat_100g'] ?? nutriments['fat'] ?? 0).toDouble();
            final fiber = (nutriments['fiber_100g'] ?? nutriments['fiber'] ?? 0)
                .toDouble();
            final imageUrl = prod['image_front_url'] ??
                prod['image_url'] ??
                _getFoodImagePlaceholder(name);

            results.add(
              FoodItem(
                id: 'off_${prod['id'] ?? DateTime.now().millisecondsSinceEpoch}',
                name: name,
                imageUrl: imageUrl.toString().isNotEmpty
                    ? imageUrl.toString()
                    : _getFoodImagePlaceholder(name),
                calories: calories > 0 ? calories : 150,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                servingSize: 100,
                servingUnit: 'g',
                category: 'General Food',
              ),
            );
          }
          if (results.isNotEmpty) return results;
        }
      }
    } catch (_) {}

    return [];
  }

  Future<ExerciseModel?> _discoverExerciseViaGemini(
      String query, String apiKey) async {
    try {
      final prompt = '''
You are a factual sports science parser. Return ONLY a valid JSON object (no markdown, no backticks, no prose) for the exercise "$query":
{
  "name": "Proper Exercise Name",
  "primaryMuscle": "Chest/Back/Shoulders/Biceps/Triceps/Quadriceps/Hamstrings/Glutes/Calves/Abdominals/Core",
  "secondaryMuscles": ["Muscle 1"],
  "equipment": "Barbell/Dumbbells/Cable Machine/Bodyweight/Machine",
  "difficulty": "Beginner/Intermediate/Advanced",
  "instructions": "Clear 2-sentence biomechanically accurate execution instruction.",
  "category": "barbells/dumbbells/cable/bodyweight/machine"
}
''';

      final rawText = await GeminiClientService.generateContent(
        apiKey: apiKey,
        prompt: prompt,
        maxTokens: 500,
        temperature: 0.2,
      );

      final cleanJson =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final map = json.decode(cleanJson);

      return ExerciseModel(
        id: 'ai_ex_${DateTime.now().millisecondsSinceEpoch}',
        name: map['name'] ?? query,
        imageUrl: '',
        primaryMuscle: map['primaryMuscle'] ?? 'Chest',
        secondaryMuscles: List<String>.from(map['secondaryMuscles'] ?? []),
        equipment: map['equipment'] ?? 'Dumbbells',
        difficulty: map['difficulty'] ?? 'Intermediate',
        instructions: map['instructions'] ??
            'Maintain posture and steady tempo throughout movement.',
        category: map['category'] ?? 'dumbbells',
      );
    } catch (_) {}
    return null;
  }

  String _getFoodImagePlaceholder(String name) {
    final n = name.toLowerCase();
    if (n.contains('pizza'))
      return 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=600&q=80';
    if (n.contains('burger'))
      return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80';
    if (n.contains('pasta') || n.contains('penne'))
      return 'https://images.unsplash.com/photo-1621996346565-e3d5d6281050?auto=format&fit=crop&w=600&q=80';
    if (n.contains('sandwich'))
      return 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=600&q=80';
    if (n.contains('salad'))
      return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=600&q=80';
    if (n.contains('chicken') || n.contains('meat') || n.contains('tikka'))
      return 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=600&q=80';
    if (n.contains('egg') || n.contains('omelette') || n.contains('bhurji'))
      return 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=600&q=80';
    if (n.contains('rice') || n.contains('biryani') || n.contains('pulao'))
      return 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=600&q=80';
    if (n.contains('paneer'))
      return 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=600&q=80';
    if (n.contains('roti') ||
        n.contains('chapati') ||
        n.contains('paratha') ||
        n.contains('naan'))
      return 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?auto=format&fit=crop&w=600&q=80';
    if (n.contains('dosa') || n.contains('idli') || n.contains('sambar'))
      return 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?auto=format&fit=crop&w=600&q=80';
    if (n.contains('shake') || n.contains('whey') || n.contains('smoothie'))
      return 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?auto=format&fit=crop&w=600&q=80';
    if (n.contains('banana') || n.contains('apple') || n.contains('fruit'))
      return 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=600&q=80';
    if (n.contains('oat'))
      return 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?auto=format&fit=crop&w=600&q=80';
    if (n.contains('curd') ||
        n.contains('dahi') ||
        n.contains('yogurt') ||
        n.contains('milk'))
      return 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=600&q=80';
    if (n.contains('dal') || n.contains('chole') || n.contains('rajma'))
      return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=600&q=80';
    return 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=600&q=80';
  }

  Future<List<FoodItem>> _discoverFoodViaGemini(
      String query, String apiKey) async {
    try {
      final prompt = '''
You are an expert sports nutritionist and culinary macro analyst.
Return ONLY a valid JSON array of 3 to 5 generic culinary variations/subcategories for "$query" (for example, if "$query" is pizza: Chicken Pizza, Sausage Pizza, Paneer Pizza, Veggie Pizza, Margherita Cheese Pizza).
DO NOT INCLUDE ANY BRAND NAMES OR STORE PRODUCTS (no Domino's, no Pizza Hut, no commercial brands).
Use intuitive portion units tailored to the specific food (e.g. 1 slice, 1 bowl, 1 piece, 1 plate, 1 glass, 1 cup, 1 burger, 1 sandwich, 100g).
Return ONLY a JSON array of objects:
[
  {
    "name": "Specific Food Variant Name",
    "calories": 280.0,
    "protein": 14.0,
    "carbs": 30.0,
    "fat": 11.0,
    "fiber": 2.5,
    "servingSize": 1.0,
    "servingUnit": "slice (110g)",
    "category": "Pizza / Italian"
  }
]
''';

      final rawText = await GeminiClientService.generateContent(
        apiKey: apiKey,
        prompt: prompt,
        maxTokens: 800,
        temperature: 0.2,
      );

      final cleanJson =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = json.decode(cleanJson);
      if (decoded is List) {
        return decoded.map((item) {
          final map = item as Map<String, dynamic>;
          final name = (map['name'] ?? query).toString();
          return FoodItem(
            id: 'ai_food_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}',
            name: name,
            calories: (map['calories'] ?? 100).toDouble(),
            protein: (map['protein'] ?? 5).toDouble(),
            carbs: (map['carbs'] ?? 15).toDouble(),
            fat: (map['fat'] ?? 2).toDouble(),
            fiber: (map['fiber'] ?? 1).toDouble(),
            servingSize: (map['servingSize'] ?? 1).toDouble(),
            servingUnit: map['servingUnit'] ?? 'serving',
            category: map['category'] ?? 'General Food',
            imageUrl: _getFoodImagePlaceholder(name),
          );
        }).toList();
      } else if (decoded is Map<String, dynamic>) {
        final name = (decoded['name'] ?? query).toString();
        return [
          FoodItem(
            id: 'ai_food_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            calories: (decoded['calories'] ?? 100).toDouble(),
            protein: (decoded['protein'] ?? 5).toDouble(),
            carbs: (decoded['carbs'] ?? 15).toDouble(),
            fat: (decoded['fat'] ?? 2).toDouble(),
            fiber: (decoded['fiber'] ?? 1).toDouble(),
            servingSize: (decoded['servingSize'] ?? 1).toDouble(),
            servingUnit: decoded['servingUnit'] ?? 'serving',
            category: decoded['category'] ?? 'General Food',
            imageUrl: _getFoodImagePlaceholder(name),
          )
        ];
      }
    } catch (_) {}
    return [];
  }

  String _mapMuscle(dynamic category) {
    final catStr = category.toString().toLowerCase();
    if (catStr.contains('chest')) return 'Chest';
    if (catStr.contains('back')) return 'Back';
    if (catStr.contains('shoulder')) return 'Shoulders';
    if (catStr.contains('arm') || catStr.contains('bicep')) return 'Biceps';
    if (catStr.contains('tricep')) return 'Triceps';
    if (catStr.contains('leg') || catStr.contains('quad')) return 'Quadriceps';
    if (catStr.contains('abs') || catStr.contains('core')) return 'Abdominals';
    return 'Full Body';
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FACTUAL VERIFIED FALLBACK DICTIONARIES
  // ═════════════════════════════════════════════════════════════════════════

  List<FoodItem> _findFallbackFoods(String clean) {
    final all = [
      // ─── PIZZA SUBCATEGORIES ─────────────────────────────────────
      FoodItem(
        id: 'fb_pizza_margherita',
        name: 'Margherita Cheese Pizza (Slice)',
        calories: 250,
        protein: 10,
        carbs: 28,
        fat: 11,
        fiber: 1.5,
        servingSize: 1,
        servingUnit: 'slice (100g)',
        category: 'Pizza & Italian',
        imageUrl: _getFoodImagePlaceholder('pizza'),
      ),
      FoodItem(
        id: 'fb_pizza_chicken',
        name: 'Chicken BBQ / Grilled Chicken Pizza (Slice)',
        calories: 290,
        protein: 16,
        carbs: 29,
        fat: 12,
        fiber: 1.5,
        servingSize: 1,
        servingUnit: 'slice (110g)',
        category: 'Pizza & Italian',
        imageUrl: _getFoodImagePlaceholder('pizza'),
      ),
      FoodItem(
        id: 'fb_pizza_paneer',
        name: 'Paneer Tikka Pizza (Slice)',
        calories: 280,
        protein: 13,
        carbs: 30,
        fat: 12,
        fiber: 2.0,
        servingSize: 1,
        servingUnit: 'slice (110g)',
        category: 'Pizza & Italian',
        imageUrl: _getFoodImagePlaceholder('pizza'),
      ),
      FoodItem(
        id: 'fb_pizza_veggie',
        name: 'Veggie Supreme Pizza (Slice)',
        calories: 230,
        protein: 8,
        carbs: 28,
        fat: 10,
        fiber: 2.5,
        servingSize: 1,
        servingUnit: 'slice (105g)',
        category: 'Pizza & Italian',
        imageUrl: _getFoodImagePlaceholder('pizza'),
      ),
      FoodItem(
        id: 'fb_pizza_sausage',
        name: 'Pepperoni & Sausage Pizza (Slice)',
        calories: 310,
        protein: 14,
        carbs: 28,
        fat: 16,
        fiber: 1.5,
        servingSize: 1,
        servingUnit: 'slice (110g)',
        category: 'Pizza & Italian',
        imageUrl: _getFoodImagePlaceholder('pizza'),
      ),

      // ─── BURGER SUBCATEGORIES ────────────────────────────────────
      FoodItem(
        id: 'fb_burger_chicken',
        name: 'Grilled Chicken Burger',
        calories: 420,
        protein: 30,
        carbs: 38,
        fat: 14,
        fiber: 3.0,
        servingSize: 1,
        servingUnit: 'burger (200g)',
        category: 'Burgers',
        imageUrl: _getFoodImagePlaceholder('burger'),
      ),
      FoodItem(
        id: 'fb_burger_veg',
        name: 'Crispy Veggie Burger',
        calories: 340,
        protein: 11,
        carbs: 45,
        fat: 12,
        fiber: 5.0,
        servingSize: 1,
        servingUnit: 'burger (180g)',
        category: 'Burgers',
        imageUrl: _getFoodImagePlaceholder('burger'),
      ),
      FoodItem(
        id: 'fb_burger_paneer',
        name: 'Spiced Paneer Burger',
        calories: 390,
        protein: 15,
        carbs: 42,
        fat: 18,
        fiber: 4.0,
        servingSize: 1,
        servingUnit: 'burger (190g)',
        category: 'Burgers',
        imageUrl: _getFoodImagePlaceholder('burger'),
      ),

      // ─── PASTA SUBCATEGORIES ─────────────────────────────────────
      FoodItem(
        id: 'fb_pasta_red',
        name: 'Penne Arrabiata (Spicy Tomato Pasta)',
        calories: 280,
        protein: 8,
        carbs: 52,
        fat: 4,
        fiber: 4.0,
        servingSize: 1,
        servingUnit: 'bowl (250g)',
        category: 'Pasta & Italian',
        imageUrl: _getFoodImagePlaceholder('pasta'),
      ),
      FoodItem(
        id: 'fb_pasta_chicken',
        name: 'Chicken Alfredo Pasta (Cream Sauce)',
        calories: 460,
        protein: 26,
        carbs: 48,
        fat: 18,
        fiber: 3.0,
        servingSize: 1,
        servingUnit: 'bowl (250g)',
        category: 'Pasta & Italian',
        imageUrl: _getFoodImagePlaceholder('pasta'),
      ),
      FoodItem(
        id: 'fb_pasta_mushroom',
        name: 'Creamy Mushroom & Herb Pasta',
        calories: 360,
        protein: 10,
        carbs: 50,
        fat: 12,
        fiber: 4.0,
        servingSize: 1,
        servingUnit: 'bowl (250g)',
        category: 'Pasta & Italian',
        imageUrl: _getFoodImagePlaceholder('pasta'),
      ),

      // ─── SANDWICH SUBCATEGORIES ──────────────────────────────────
      FoodItem(
        id: 'fb_sandwich_chicken',
        name: 'Grilled Chicken Breast Sandwich',
        calories: 320,
        protein: 24,
        carbs: 32,
        fat: 9,
        fiber: 3.0,
        servingSize: 1,
        servingUnit: 'sandwich',
        category: 'Sandwiches',
        imageUrl: _getFoodImagePlaceholder('sandwich'),
      ),
      FoodItem(
        id: 'fb_sandwich_paneer',
        name: 'Paneer Tikka Grilled Sandwich',
        calories: 290,
        protein: 13,
        carbs: 34,
        fat: 11,
        fiber: 3.5,
        servingSize: 1,
        servingUnit: 'sandwich',
        category: 'Sandwiches',
        imageUrl: _getFoodImagePlaceholder('sandwich'),
      ),
      FoodItem(
        id: 'fb_sandwich_veg',
        name: 'Veg Club Sandwich (Multi-Grain)',
        calories: 250,
        protein: 7,
        carbs: 36,
        fat: 8,
        fiber: 4.0,
        servingSize: 1,
        servingUnit: 'sandwich',
        category: 'Sandwiches',
        imageUrl: _getFoodImagePlaceholder('sandwich'),
      ),
      FoodItem(
        id: 'fb_sandwich_egg',
        name: 'Boiled Egg & Herb Sandwich',
        calories: 275,
        protein: 16,
        carbs: 28,
        fat: 10,
        fiber: 2.0,
        servingSize: 1,
        servingUnit: 'sandwich',
        category: 'Sandwiches',
        imageUrl: _getFoodImagePlaceholder('sandwich'),
      ),

      // ─── RICE & GRAINS SUBCATEGORIES ─────────────────────────────
      FoodItem(
        id: 'fb_rice_white',
        name: 'Steamed White Basmati Rice',
        calories: 195,
        protein: 4.3,
        carbs: 44,
        fat: 0.4,
        fiber: 0.6,
        servingSize: 1,
        servingUnit: 'cup (150g)',
        category: 'Rice and Grains',
        imageUrl: _getFoodImagePlaceholder('rice'),
      ),
      FoodItem(
        id: 'fb_rice_brown',
        name: 'Brown Basmati Rice',
        calories: 165,
        protein: 3.8,
        carbs: 35,
        fat: 1.4,
        fiber: 2.5,
        servingSize: 1,
        servingUnit: 'cup (150g)',
        category: 'Rice and Grains',
        imageUrl: _getFoodImagePlaceholder('rice'),
      ),
      FoodItem(
        id: 'fb_chicken_biryani',
        name: 'Chicken Dum Biryani',
        calories: 420,
        protein: 28,
        carbs: 48,
        fat: 12,
        fiber: 3.0,
        servingSize: 1,
        servingUnit: 'plate (300g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('biryani'),
      ),
      FoodItem(
        id: 'fb_veg_biryani',
        name: 'Vegetable Pulao / Biryani',
        calories: 310,
        protein: 7,
        carbs: 52,
        fat: 8,
        fiber: 4.5,
        servingSize: 1,
        servingUnit: 'plate (250g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('rice'),
      ),
      FoodItem(
        id: 'fb_egg_fried_rice',
        name: 'Egg Fried Rice',
        calories: 360,
        protein: 14,
        carbs: 48,
        fat: 11,
        fiber: 2.5,
        servingSize: 1,
        servingUnit: 'plate (250g)',
        category: 'Rice and Grains',
        imageUrl: _getFoodImagePlaceholder('rice'),
      ),

      // ─── CHICKEN & POULTRY ───────────────────────────────────────
      FoodItem(
        id: 'fb_chicken_breast',
        name: 'Grilled Chicken Breast',
        calories: 245,
        protein: 46,
        carbs: 0,
        fat: 5.5,
        fiber: 0.0,
        servingSize: 150,
        servingUnit: 'g',
        category: 'Meat',
        imageUrl: _getFoodImagePlaceholder('chicken'),
      ),
      FoodItem(
        id: 'fb_chicken_curry',
        name: 'Homestyle Chicken Curry',
        calories: 280,
        protein: 24,
        carbs: 8,
        fat: 16,
        fiber: 2.0,
        servingSize: 1,
        servingUnit: 'bowl (200g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('chicken'),
      ),
      FoodItem(
        id: 'fb_tandoori_chicken',
        name: 'Tandoori Chicken Breast Piece',
        calories: 260,
        protein: 32,
        carbs: 5,
        fat: 11,
        fiber: 1.5,
        servingSize: 1,
        servingUnit: 'piece (180g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('chicken'),
      ),
      FoodItem(
        id: 'fb_butter_chicken',
        name: 'Butter Chicken (Murgh Makhani)',
        calories: 380,
        protein: 22,
        carbs: 12,
        fat: 26,
        fiber: 2.0,
        servingSize: 1,
        servingUnit: 'bowl (200g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('chicken'),
      ),

      // ─── EGGS ────────────────────────────────────────────────────
      FoodItem(
        id: 'fb_boiled_eggs',
        name: 'Whole Boiled Eggs (2 eggs)',
        calories: 156,
        protein: 13,
        carbs: 1.1,
        fat: 10.6,
        fiber: 0,
        servingSize: 2,
        servingUnit: 'eggs (100g)',
        category: 'Eggs',
        imageUrl: _getFoodImagePlaceholder('egg'),
      ),
      FoodItem(
        id: 'fb_egg_omelette',
        name: 'Egg Omelette (2 eggs with herbs)',
        calories: 180,
        protein: 14,
        carbs: 2,
        fat: 12,
        fiber: 0.5,
        servingSize: 1,
        servingUnit: 'omelette (2 eggs)',
        category: 'Eggs',
        imageUrl: _getFoodImagePlaceholder('egg'),
      ),
      FoodItem(
        id: 'fb_egg_whites',
        name: 'Egg White Scramble (3 whites)',
        calories: 52,
        protein: 11,
        carbs: 0.7,
        fat: 0.2,
        fiber: 0,
        servingSize: 3,
        servingUnit: 'egg whites',
        category: 'Eggs',
        imageUrl: _getFoodImagePlaceholder('egg'),
      ),
      FoodItem(
        id: 'fb_egg_bhurji',
        name: 'Egg Bhurji (Indian Scrambled Eggs)',
        calories: 210,
        protein: 15,
        carbs: 5,
        fat: 14,
        fiber: 1.5,
        servingSize: 1,
        servingUnit: 'plate (150g)',
        category: 'Eggs',
        imageUrl: _getFoodImagePlaceholder('egg'),
      ),

      // ─── PANEER & DAIRY ──────────────────────────────────────────
      FoodItem(
        id: 'fb_paneer_raw',
        name: 'Fresh Raw Paneer (Cottage Cheese)',
        calories: 265,
        protein: 18,
        carbs: 3,
        fat: 21,
        fiber: 0,
        servingSize: 100,
        servingUnit: 'g',
        category: 'Dairy',
        imageUrl: _getFoodImagePlaceholder('paneer'),
      ),
      FoodItem(
        id: 'fb_paneer_tikka',
        name: 'Paneer Tikka (Grilled)',
        calories: 260,
        protein: 16,
        carbs: 10,
        fat: 16,
        fiber: 2,
        servingSize: 1,
        servingUnit: 'plate (150g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('paneer'),
      ),
      FoodItem(
        id: 'fb_paneer_bhurji',
        name: 'Paneer Bhurji',
        calories: 240,
        protein: 14,
        carbs: 7,
        fat: 17,
        fiber: 2,
        servingSize: 1,
        servingUnit: 'bowl (150g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('paneer'),
      ),
      FoodItem(
        id: 'fb_palak_paneer',
        name: 'Palak Paneer (Spinach Cottage Cheese)',
        calories: 230,
        protein: 12,
        carbs: 9,
        fat: 16,
        fiber: 4,
        servingSize: 1,
        servingUnit: 'bowl (200g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('paneer'),
      ),
      FoodItem(
        id: 'fb_curd',
        name: 'Plain Curd / Dahi',
        calories: 98,
        protein: 6.0,
        carbs: 7.0,
        fat: 5.0,
        fiber: 0,
        servingSize: 1,
        servingUnit: 'bowl (150g)',
        category: 'Dairy',
        imageUrl: _getFoodImagePlaceholder('curd'),
      ),

      // ─── INDIAN BREADS & STAPLES ─────────────────────────────────
      FoodItem(
        id: 'fb_chapati',
        name: 'Whole Wheat Roti / Chapati',
        calories: 104,
        protein: 3.1,
        carbs: 18.5,
        fat: 2.0,
        fiber: 2.8,
        servingSize: 1,
        servingUnit: 'roti (40g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('roti'),
      ),
      FoodItem(
        id: 'fb_paratha_plain',
        name: 'Plain Tawa Paratha',
        calories: 180,
        protein: 4.0,
        carbs: 26,
        fat: 6.5,
        fiber: 3.0,
        servingSize: 1,
        servingUnit: 'paratha (60g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('paratha'),
      ),
      FoodItem(
        id: 'fb_paratha_aloo',
        name: 'Aloo Paratha (Stuffed)',
        calories: 260,
        protein: 5.5,
        carbs: 38,
        fat: 9.5,
        fiber: 4.0,
        servingSize: 1,
        servingUnit: 'paratha (90g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('paratha'),
      ),
      FoodItem(
        id: 'fb_naan_butter',
        name: 'Butter Naan',
        calories: 290,
        protein: 8.0,
        carbs: 46,
        fat: 8.5,
        fiber: 2.0,
        servingSize: 1,
        servingUnit: 'naan (90g)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('naan'),
      ),
      FoodItem(
        id: 'fb_dosa_plain',
        name: 'Plain Crispy Dosa',
        calories: 168,
        protein: 3.8,
        carbs: 29,
        fat: 3.7,
        fiber: 1.5,
        servingSize: 1,
        servingUnit: 'dosa (80g)',
        category: 'South Indian',
        imageUrl: _getFoodImagePlaceholder('dosa'),
      ),
      FoodItem(
        id: 'fb_dosa_masala',
        name: 'Masala Dosa (Potato Filling)',
        calories: 250,
        protein: 5.2,
        carbs: 42,
        fat: 6.8,
        fiber: 3.0,
        servingSize: 1,
        servingUnit: 'dosa (150g)',
        category: 'South Indian',
        imageUrl: _getFoodImagePlaceholder('dosa'),
      ),
      FoodItem(
        id: 'fb_idli',
        name: 'Steamed Rice Idli (2 pieces)',
        calories: 116,
        protein: 4.0,
        carbs: 24,
        fat: 0.4,
        fiber: 1.6,
        servingSize: 2,
        servingUnit: 'pieces (80g)',
        category: 'South Indian',
        imageUrl: _getFoodImagePlaceholder('idli'),
      ),
      FoodItem(
        id: 'fb_dal_tadka',
        name: 'Yellow Dal Tadka',
        calories: 155,
        protein: 8.5,
        carbs: 22,
        fat: 3.8,
        fiber: 4.2,
        servingSize: 1,
        servingUnit: 'bowl (150ml)',
        category: 'North Indian',
        imageUrl: _getFoodImagePlaceholder('dal'),
      ),

      // ─── SHAKES & SUPPLEMENTS ────────────────────────────────────
      FoodItem(
        id: 'fb_whey_water',
        name: 'Whey Protein Isolate (in Water)',
        calories: 120,
        protein: 25,
        carbs: 2,
        fat: 0.5,
        fiber: 0,
        servingSize: 1,
        servingUnit: 'scoop (30g)',
        category: 'Supplements',
        imageUrl: _getFoodImagePlaceholder('shake'),
      ),
      FoodItem(
        id: 'fb_whey_milk',
        name: 'Whey Protein Shake (in Milk)',
        calories: 270,
        protein: 33,
        carbs: 14,
        fat: 7.5,
        fiber: 0,
        servingSize: 1,
        servingUnit: 'shake (280ml)',
        category: 'Supplements',
        imageUrl: _getFoodImagePlaceholder('shake'),
      ),
      FoodItem(
        id: 'fb_smoothie_banana',
        name: 'Banana Peanut Butter Smoothie',
        calories: 340,
        protein: 14,
        carbs: 42,
        fat: 13,
        fiber: 4.5,
        servingSize: 1,
        servingUnit: 'glass (300ml)',
        category: 'Breakfast',
        imageUrl: _getFoodImagePlaceholder('banana'),
      ),
      FoodItem(
        id: 'fb_oats',
        name: 'Rolled Oats with Milk & Honey',
        calories: 220,
        protein: 8.5,
        carbs: 38,
        fat: 4.0,
        fiber: 4.5,
        servingSize: 1,
        servingUnit: 'bowl (200g)',
        category: 'Breakfast',
        imageUrl: _getFoodImagePlaceholder('oats'),
      ),
    ];

    return all.where((f) {
      final nameLower = f.name.toLowerCase();
      final catLower = f.category.toLowerCase();
      return nameLower.contains(clean) || catLower.contains(clean);
    }).toList();
  }

  List<ExerciseModel> _findFallbackExercises(String clean) {
    final all = [
      const ExerciseModel(
        id: 'fb_bench_press',
        name: 'Barbell Flat Bench Press',
        imageUrl: '',
        primaryMuscle: 'Chest',
        secondaryMuscles: ['Triceps', 'Anterior Deltoid'],
        equipment: 'Barbell & Bench',
        difficulty: 'Intermediate',
        instructions:
            'Plant feet flat, retract shoulder blades, lower bar to mid-chest, and press explosively with elbows tucked at 45 degrees.',
        category: 'barbell',
      ),
      const ExerciseModel(
        id: 'fb_incline_db_press',
        name: 'Incline Dumbbell Bench Press',
        imageUrl: '',
        primaryMuscle: 'Chest',
        secondaryMuscles: ['Anterior Deltoid', 'Triceps'],
        equipment: 'Dumbbells',
        difficulty: 'Intermediate',
        instructions:
            'Set bench to 30 degrees, press dumbbells overhead in a slight arc, and lower with controlled 3-second eccentric tempo.',
        category: 'dumbbell',
      ),
      const ExerciseModel(
        id: 'fb_squat',
        name: 'Barbell Back Squat',
        imageUrl: '',
        primaryMuscle: 'Quadriceps',
        secondaryMuscles: ['Glutes', 'Hamstrings', 'Core'],
        equipment: 'Barbell & Squat Rack',
        difficulty: 'Advanced',
        instructions:
            'Descend to parallel while pushing knees in line with toes, maintain braced abdominal pressure, and drive out of the hole.',
        category: 'barbell',
      ),
      const ExerciseModel(
        id: 'fb_romanian_deadlift',
        name: 'Romanian Deadlift (RDL)',
        imageUrl: '',
        primaryMuscle: 'Hamstrings',
        secondaryMuscles: ['Glutes', 'Erector Spinae'],
        equipment: 'Barbell or Dumbbells',
        difficulty: 'Intermediate',
        instructions:
            'Hinge back at the hips with soft knees, feel deep hamstring stretch below knees, and engage glutes to return upright.',
        category: 'barbell',
      ),
      const ExerciseModel(
        id: 'fb_lateral_raise',
        name: 'Dumbbell Lateral Raise',
        imageUrl: '',
        primaryMuscle: 'Shoulders',
        secondaryMuscles: ['Traps'],
        equipment: 'Dumbbells',
        difficulty: 'Beginner',
        instructions:
            'Raise dumbbells in scapular plane with slight forward lean, lead with elbows to shoulder height, and control the descent.',
        category: 'dumbbell',
      ),
      const ExerciseModel(
        id: 'fb_lat_pulldown',
        name: 'Cable Lat Pulldown',
        imageUrl: '',
        primaryMuscle: 'Back',
        secondaryMuscles: ['Biceps', 'Rear Delts'],
        equipment: 'Cable Machine',
        difficulty: 'Beginner',
        instructions:
            'Grip slightly outside shoulders, pull bar down toward clavicle while depressing scapula, and stretch fully at the top.',
        category: 'cable',
      ),
      const ExerciseModel(
        id: 'fb_bicep_curl',
        name: 'Incline Dumbbell Bicep Curl',
        imageUrl: '',
        primaryMuscle: 'Biceps',
        secondaryMuscles: ['Forearms'],
        equipment: 'Dumbbells & Incline Bench',
        difficulty: 'Beginner',
        instructions:
            'Lie back on 45-degree incline, keep elbows locked in position behind torso, and curl with full supination at the peak.',
        category: 'dumbbell',
      ),
      const ExerciseModel(
        id: 'fb_triceps_pushdown',
        name: 'Cable Triceps Rope Pushdown',
        imageUrl: '',
        primaryMuscle: 'Triceps',
        secondaryMuscles: [],
        equipment: 'Cable Machine',
        difficulty: 'Beginner',
        instructions:
            'Pin elbows to sides, press rope downward until arms lock out, flare rope ends apart, and control return to 90 degrees.',
        category: 'cable',
      ),
    ];

    return all
        .where((e) =>
            e.name.toLowerCase().contains(clean) ||
            e.primaryMuscle.toLowerCase().contains(clean) ||
            e.equipment.toLowerCase().contains(clean))
        .toList();
  }
}
