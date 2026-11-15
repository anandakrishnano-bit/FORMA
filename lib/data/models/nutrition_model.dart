import 'package:cloud_firestore/cloud_firestore.dart';

/// A food item in the food database.
typedef FoodItem = Food;

class Food {
  final String id;
  final String name;
  final String category;
  final String servingUnit;
  final double servingWeight;
  final double servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final bool isCustom;
  final String createdBy;
  final String imageUrl;
  final bool isBranded;
  final String? brandName;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    this.servingUnit = 'g',
    this.servingWeight = 100.0,
    double? servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    this.sugar = 0.0,
    this.isCustom = false,
    this.createdBy = '',
    this.imageUrl = '',
    this.isBranded = false,
    this.brandName,
  }) : servingSize = servingSize ?? servingWeight;

  factory Food.fromJson(Map<String, dynamic> json) => Food.fromMap(json);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'servingUnit': servingUnit,
        'servingWeight': servingWeight,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
        'isCustom': isCustom,
        'createdBy': createdBy,
        'imageUrl': imageUrl,
        'isBranded': isBranded,
        'brandName': brandName,
      };

  factory Food.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Food(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      servingUnit: data['servingUnit'] as String? ?? 'g',
      servingWeight: (data['servingWeight'] as num?)?.toDouble() ?? 100.0,
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (data['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (data['sugar'] as num?)?.toDouble() ?? 0.0,
      isCustom: data['isCustom'] as bool? ?? false,
      createdBy: data['createdBy'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      isBranded: data['isBranded'] as bool? ?? false,
      brandName: data['brandName'] as String?,
    );
  }

  factory Food.fromMap(Map<String, dynamic> data) {
    return Food(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      servingUnit: data['servingUnit'] as String? ?? 'g',
      servingWeight: (data['servingWeight'] as num?)?.toDouble() ?? 100.0,
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (data['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (data['sugar'] as num?)?.toDouble() ?? 0.0,
      isCustom: data['isCustom'] as bool? ?? false,
      createdBy: data['createdBy'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      isBranded: data['isBranded'] as bool? ?? false,
      brandName: data['brandName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'servingUnit': servingUnit,
      'servingWeight': servingWeight,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'isCustom': isCustom,
      'createdBy': createdBy,
      'imageUrl': imageUrl,
      'isBranded': isBranded,
      'brandName': brandName,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      ...toFirestore(),
    };
  }

  /// Structured food-specific portion tiers (Small, Medium, Large, Custom)
  List<FoodPortion> get structuredPortions {
    final n = name.toLowerCase();
    final c = category.toLowerCase();

    // 1. Rice, Biryani, Pulao, Khichdi
    if (n.contains('rice') ||
        n.contains('biryani') ||
        n.contains('pulao') ||
        n.contains('khichdi')) {
      return const [
        FoodPortion(
          tier: PortionTier.small,
          label: 'Small',
          gramEquivalent: 100.0,
          unitDescription: 'Small bowl (100g cooked)',
          icon: '🥣',
        ),
        FoodPortion(
          tier: PortionTier.medium,
          label: 'Medium',
          gramEquivalent: 150.0,
          unitDescription: 'Medium bowl / Katori (150g)',
          icon: '🥣',
        ),
        FoodPortion(
          tier: PortionTier.large,
          label: 'Large',
          gramEquivalent: 250.0,
          unitDescription: 'Full plate serving (250g)',
          icon: '🍽️',
        ),
      ];
    }

    // 2. Roti, Chapati, Naan, Paratha
    if (n.contains('roti') ||
        n.contains('chapati') ||
        n.contains('naan') ||
        n.contains('paratha')) {
      final isStuffed = n.contains('paratha') || n.contains('naan');
      return [
        FoodPortion(
          tier: PortionTier.small,
          label: 'Small',
          gramEquivalent: isStuffed ? 60.0 : 30.0,
          unitDescription:
              isStuffed ? 'Small piece (60g)' : 'Small thin chapati (30g)',
          icon: '🫓',
        ),
        FoodPortion(
          tier: PortionTier.medium,
          label: 'Medium',
          gramEquivalent: isStuffed ? 85.0 : 45.0,
          unitDescription:
              isStuffed ? 'Standard piece (85g)' : 'Standard chapati (45g)',
          icon: '🫓',
        ),
        FoodPortion(
          tier: PortionTier.large,
          label: 'Large',
          gramEquivalent: isStuffed ? 130.0 : 65.0,
          unitDescription: isStuffed
              ? 'Large thick piece (130g)'
              : 'Large thick chapati (65g)',
          icon: '🫓',
        ),
      ];
    }

    // 3. Idli, Dosa
    if (n.contains('idli') || n.contains('dosa')) {
      final isDosa = n.contains('dosa');
      return [
        FoodPortion(
          tier: PortionTier.small,
          label: 'Small',
          gramEquivalent: isDosa ? 50.0 : 40.0,
          unitDescription: isDosa ? 'Small plain dosa (50g)' : '1 idli (40g)',
          icon: '🥞',
        ),
        FoodPortion(
          tier: PortionTier.medium,
          label: 'Medium',
          gramEquivalent: isDosa ? 90.0 : 80.0,
          unitDescription:
              isDosa ? 'Regular masala/plain dosa (90g)' : '2 idlis (80g)',
          icon: '🥞',
        ),
        FoodPortion(
          tier: PortionTier.large,
          label: 'Large',
          gramEquivalent: isDosa ? 150.0 : 120.0,
          unitDescription:
              isDosa ? 'Special large dosa (150g)' : '3 idlis (120g)',
          icon: '🥞',
        ),
      ];
    }

    // 4. Milk, Juice, Smoothies, Coffee, Tea
    if (n.contains('milk') ||
        n.contains('shake') ||
        n.contains('smoothie') ||
        n.contains('juice') ||
        n.contains('coffee') ||
        n.contains('tea')) {
      return const [
        FoodPortion(
          tier: PortionTier.small,
          label: 'Small',
          gramEquivalent: 150.0,
          unitDescription: 'Small cup (150 ml)',
          icon: '☕',
        ),
        FoodPortion(
          tier: PortionTier.medium,
          label: 'Medium',
          gramEquivalent: 250.0,
          unitDescription: 'Standard glass (250 ml)',
          icon: '🥛',
        ),
        FoodPortion(
          tier: PortionTier.large,
          label: 'Large',
          gramEquivalent: 350.0,
          unitDescription: 'Large mug (350 ml)',
          icon: '🥤',
        ),
      ];
    }

    // 5. Eggs
    if (n.contains('egg')) {
      return const [
        FoodPortion(
          tier: PortionTier.small,
          label: 'Small',
          gramEquivalent: 50.0,
          unitDescription: '1 whole egg (50g)',
          icon: '🥚',
        ),
        FoodPortion(
          tier: PortionTier.medium,
          label: 'Medium',
          gramEquivalent: 100.0,
          unitDescription: '2 whole eggs (100g)',
          icon: '🥚',
        ),
        FoodPortion(
          tier: PortionTier.large,
          label: 'Large',
          gramEquivalent: 150.0,
          unitDescription: '3 whole eggs (150g)',
          icon: '🥚',
        ),
      ];
    }

    // 6. Chicken, Meat, Fish, Paneer, Tofu
    if (n.contains('chicken') ||
        n.contains('meat') ||
        n.contains('fish') ||
        n.contains('salmon') ||
        n.contains('paneer') ||
        n.contains('tofu')) {
      return const [
        FoodPortion(
          tier: PortionTier.small,
          label: 'Small',
          gramEquivalent: 100.0,
          unitDescription: 'Small palm portion (100g)',
          icon: '🥩',
        ),
        FoodPortion(
          tier: PortionTier.medium,
          label: 'Medium',
          gramEquivalent: 150.0,
          unitDescription: 'Standard cooked portion (150g)',
          icon: '🥩',
        ),
        FoodPortion(
          tier: PortionTier.large,
          label: 'Large',
          gramEquivalent: 250.0,
          unitDescription: 'Generous active portion (250g)',
          icon: '🥩',
        ),
      ];
    }

    // 7. Dal, Sambar, Curry, Soup, Chole, Rajma
    if (n.contains('dal') ||
        n.contains('sambar') ||
        n.contains('curry') ||
        n.contains('soup') ||
        n.contains('chole') ||
        n.contains('rajma')) {
      return const [
        FoodPortion(
          tier: PortionTier.small,
          label: 'Small',
          gramEquivalent: 100.0,
          unitDescription: 'Small katori (100g)',
          icon: '🥣',
        ),
        FoodPortion(
          tier: PortionTier.medium,
          label: 'Medium',
          gramEquivalent: 150.0,
          unitDescription: 'Standard bowl (150g)',
          icon: '🥣',
        ),
        FoodPortion(
          tier: PortionTier.large,
          label: 'Large',
          gramEquivalent: 250.0,
          unitDescription: 'Large bowl (250g)',
          icon: '🥣',
        ),
      ];
    }

    // 8. Bread, Toast
    if (n.contains('bread') || n.contains('toast')) {
      return const [
        FoodPortion(
          tier: PortionTier.small,
          label: 'Small',
          gramEquivalent: 30.0,
          unitDescription: '1 slice (30g)',
          icon: '🍞',
        ),
        FoodPortion(
          tier: PortionTier.medium,
          label: 'Medium',
          gramEquivalent: 60.0,
          unitDescription: '2 slices (60g)',
          icon: '🍞',
        ),
        FoodPortion(
          tier: PortionTier.large,
          label: 'Large',
          gramEquivalent: 90.0,
          unitDescription: '3 slices (90g)',
          icon: '🍞',
        ),
      ];
    }

    // 9. Fruits
    if (n.contains('apple') ||
        n.contains('banana') ||
        n.contains('orange') ||
        c.contains('fruit')) {
      return const [
        FoodPortion(
          tier: PortionTier.small,
          label: 'Small',
          gramEquivalent: 80.0,
          unitDescription: 'Small piece (80g)',
          icon: '🍎',
        ),
        FoodPortion(
          tier: PortionTier.medium,
          label: 'Medium',
          gramEquivalent: 120.0,
          unitDescription: 'Medium standard piece (120g)',
          icon: '🍎',
        ),
        FoodPortion(
          tier: PortionTier.large,
          label: 'Large',
          gramEquivalent: 180.0,
          unitDescription: 'Large piece (180g)',
          icon: '🍎',
        ),
      ];
    }

    // Universal Default
    final base = servingWeight > 0
        ? servingWeight
        : (servingSize > 0 ? servingSize : 100.0);
    return [
      FoodPortion(
        tier: PortionTier.small,
        label: 'Small',
        gramEquivalent: (base * 0.7).roundToDouble(),
        unitDescription:
            'Small portion (${(base * 0.7).toInt()}${servingUnit.isNotEmpty ? servingUnit : 'g'})',
        icon: '🍽️',
      ),
      FoodPortion(
        tier: PortionTier.medium,
        label: 'Medium',
        gramEquivalent: base,
        unitDescription:
            'Standard portion (${base.toInt()}${servingUnit.isNotEmpty ? servingUnit : 'g'})',
        icon: '🍽️',
      ),
      FoodPortion(
        tier: PortionTier.large,
        label: 'Large',
        gramEquivalent: (base * 1.5).roundToDouble(),
        unitDescription:
            'Large portion (${(base * 1.5).toInt()}${servingUnit.isNotEmpty ? servingUnit : 'g'})',
        icon: '🍽️',
      ),
    ];
  }

  /// Exact nutrition calculation from reference grams:
  /// Nutrient amount = selected food weight / base serving weight * nutrient value
  ({double calories, double protein, double carbs, double fat, double fiber})
      calculateNutrientsForGrams(double targetGrams) {
    final base = servingWeight > 0
        ? servingWeight
        : (servingSize > 0 ? servingSize : 100.0);
    final ratio = targetGrams / (base > 0 ? base : 100.0);
    return (
      calories: calories * ratio,
      protein: protein * ratio,
      carbs: carbs * ratio,
      fat: fat * ratio,
      fiber: fiber * ratio,
    );
  }

  /// Real culinary portion options dynamically tailored to this food type
  List<PortionOption> get availablePortions {
    final n = name.toLowerCase();
    final c = category.toLowerCase();

    if (n.contains('pizza')) {
      return const [
        PortionOption(label: 'Slice', gramEquivalent: 105.0, icon: '🍕'),
        PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
        PortionOption(
            label: 'Small Personal (8")', gramEquivalent: 300.0, icon: '🍕'),
        PortionOption(
            label: 'Medium Whole (12")', gramEquivalent: 620.0, icon: '🍕'),
      ];
    }
    if (n.contains('rice') ||
        n.contains('biryani') ||
        n.contains('pulao') ||
        n.contains('khichdi')) {
      return const [
        PortionOption(
            label: 'Medium Bowl (Katori)', gramEquivalent: 150.0, icon: '🥣'),
        PortionOption(
            label: 'Plate / Full Serving', gramEquivalent: 250.0, icon: '🍽️'),
        PortionOption(label: 'Cup (Cooked)', gramEquivalent: 180.0, icon: '🍵'),
        PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
      ];
    }
    if (n.contains('roti') ||
        n.contains('chapati') ||
        n.contains('naan') ||
        n.contains('paratha')) {
      final isStuffed = n.contains('paratha') || n.contains('naan');
      return [
        PortionOption(
            label: '1 Piece',
            gramEquivalent: isStuffed ? 80.0 : 40.0,
            icon: '🫓'),
        PortionOption(
            label: '2 Pieces',
            gramEquivalent: isStuffed ? 160.0 : 80.0,
            icon: '🫓'),
        const PortionOption(
            label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
      ];
    }
    if (n.contains('dal') ||
        n.contains('sambar') ||
        n.contains('curry') ||
        n.contains('soup') ||
        n.contains('chole') ||
        n.contains('rajma')) {
      return const [
        PortionOption(
            label: 'Bowl (1 Katori)', gramEquivalent: 150.0, icon: '🥣'),
        PortionOption(label: 'Large Bowl', gramEquivalent: 250.0, icon: '🥣'),
        PortionOption(
            label: 'Tablespoon (tbsp)', gramEquivalent: 15.0, icon: '🥄'),
        PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
      ];
    }
    if (n.contains('milk') ||
        n.contains('shake') ||
        n.contains('smoothie') ||
        n.contains('juice') ||
        n.contains('coffee') ||
        n.contains('tea')) {
      return const [
        PortionOption(
            label: 'Glass (250 ml)', gramEquivalent: 250.0, icon: '🥛'),
        PortionOption(label: 'Cup (150 ml)', gramEquivalent: 150.0, icon: '☕'),
        PortionOption(label: 'Mug (350 ml)', gramEquivalent: 350.0, icon: '🥤'),
        PortionOption(
            label: 'Milliliters (ml)', gramEquivalent: 1.0, icon: '⚖️'),
      ];
    }
    if (n.contains('chicken') ||
        n.contains('meat') ||
        n.contains('fish') ||
        n.contains('salmon') ||
        n.contains('paneer') ||
        n.contains('tofu')) {
      return const [
        PortionOption(
            label: 'Standard Serving', gramEquivalent: 150.0, icon: '🥩'),
        PortionOption(label: 'Palm Sized', gramEquivalent: 100.0, icon: '🖐️'),
        PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
        PortionOption(label: 'Ounces (oz)', gramEquivalent: 28.35, icon: '⚖️'),
      ];
    }
    if (n.contains('egg')) {
      return const [
        PortionOption(label: '1 Whole Egg', gramEquivalent: 50.0, icon: '🥚'),
        PortionOption(label: '2 Whole Eggs', gramEquivalent: 100.0, icon: '🥚'),
        PortionOption(label: '1 Egg White', gramEquivalent: 33.0, icon: '🥚'),
        PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
      ];
    }
    if (n.contains('banana') ||
        n.contains('apple') ||
        n.contains('orange') ||
        c.contains('fruit')) {
      return const [
        PortionOption(
            label: '1 Medium Piece', gramEquivalent: 120.0, icon: '🍎'),
        PortionOption(
            label: '1 Large Piece', gramEquivalent: 180.0, icon: '🍎'),
        PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
      ];
    }
    if (n.contains('bread') || n.contains('toast')) {
      return const [
        PortionOption(label: '1 Slice', gramEquivalent: 30.0, icon: '🍞'),
        PortionOption(label: '2 Slices', gramEquivalent: 60.0, icon: '🍞'),
        PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
      ];
    }
    if (n.contains('burger') ||
        n.contains('sandwich') ||
        n.contains('wrap') ||
        n.contains('roll')) {
      return const [
        PortionOption(label: '1 Item', gramEquivalent: 180.0, icon: '🍔'),
        PortionOption(label: 'Half Item', gramEquivalent: 90.0, icon: '🍔'),
        PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
      ];
    }
    if (n.contains('oats') || n.contains('cereal') || n.contains('muesli')) {
      return const [
        PortionOption(label: 'Cooked Bowl', gramEquivalent: 200.0, icon: '🥣'),
        PortionOption(
            label: 'Dry Scoop / Serving', gramEquivalent: 40.0, icon: '🥄'),
        PortionOption(
            label: 'Tablespoon (tbsp)', gramEquivalent: 15.0, icon: '🥄'),
        PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
      ];
    }
    if (n.contains('protein') || n.contains('whey')) {
      return const [
        PortionOption(label: '1 Scoop (30g)', gramEquivalent: 30.0, icon: '🥄'),
        PortionOption(
            label: '1.5 Scoops (45g)', gramEquivalent: 45.0, icon: '🥄'),
        PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
      ];
    }

    // Default universal portion options
    final baseWeight = servingWeight > 0
        ? servingWeight
        : (servingSize > 0 ? servingSize : 100.0);
    return [
      PortionOption(
        label: servingUnit.isNotEmpty && servingUnit != 'g'
            ? 'Serving ($servingUnit)'
            : 'Serving (${baseWeight.toInt()}g)',
        gramEquivalent: baseWeight,
        icon: '🍽️',
      ),
      const PortionOption(label: 'Grams (g)', gramEquivalent: 1.0, icon: '⚖️'),
      const PortionOption(
          label: 'Medium Bowl', gramEquivalent: 150.0, icon: '🥣'),
      const PortionOption(
          label: 'Tablespoon (tbsp)', gramEquivalent: 15.0, icon: '🥄'),
    ];
  }
}

/// Distinct portion size tiers (Small, Medium, Large, Custom)
enum PortionTier { small, medium, large, custom }

/// Structured food portion representation
class FoodPortion {
  final PortionTier tier;
  final String label;
  final double gramEquivalent;
  final String unitDescription;
  final String icon;

  const FoodPortion({
    required this.tier,
    required this.label,
    required this.gramEquivalent,
    required this.unitDescription,
    this.icon = '',
  });

  Map<String, dynamic> toMap() => {
        'tier': tier.name,
        'label': label,
        'gramEquivalent': gramEquivalent,
        'unitDescription': unitDescription,
        'icon': icon,
      };

  factory FoodPortion.fromMap(Map<String, dynamic> map) {
    final tierStr = map['tier'] as String? ?? 'medium';
    final tier = PortionTier.values.firstWhere(
      (e) => e.name == tierStr,
      orElse: () => PortionTier.medium,
    );
    return FoodPortion(
      tier: tier,
      label: map['label'] as String? ?? 'Medium',
      gramEquivalent: (map['gramEquivalent'] as num?)?.toDouble() ?? 100.0,
      unitDescription: map['unitDescription'] as String? ?? '',
      icon: map['icon'] as String? ?? '',
    );
  }
}

/// Saved custom portion privately stored for an individual user
class CustomPortion {
  final String id;
  final String userId;
  final String foodId;
  final String foodName;
  final String label;
  final double gramEquivalent;
  final DateTime createdAt;

  const CustomPortion({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.foodName,
    required this.label,
    required this.gramEquivalent,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'foodId': foodId,
        'foodName': foodName,
        'label': label,
        'gramEquivalent': gramEquivalent,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory CustomPortion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CustomPortion(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      foodId: data['foodId'] as String? ?? '',
      foodName: data['foodName'] as String? ?? '',
      label: data['label'] as String? ?? '',
      gramEquivalent: (data['gramEquivalent'] as num?)?.toDouble() ?? 100.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// A specific portion unit (e.g. Slice, Bowl, Gram, Cup)
class PortionOption {
  final String label;
  final double gramEquivalent;
  final String icon;

  const PortionOption({
    required this.label,
    required this.gramEquivalent,
    this.icon = '',
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'gramEquivalent': gramEquivalent,
        'icon': icon,
      };

  factory PortionOption.fromMap(Map<String, dynamic> map) => PortionOption(
        label: map['label'] as String? ?? 'Serving',
        gramEquivalent: (map['gramEquivalent'] as num?)?.toDouble() ?? 100.0,
        icon: map['icon'] as String? ?? '',
      );
}

/// Meal type for categorizing daily meals.
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  static MealType fromString(String value) {
    final v = value.trim().toLowerCase();
    return MealType.values.firstWhere(
      (e) => e.name.toLowerCase() == v || e.displayName.toLowerCase() == v,
      orElse: () => MealType.snack,
    );
  }
}

class MealFood {
  final String foodId;
  final String foodName;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const MealFood({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toMap() => {
        'foodId': foodId,
        'foodName': foodName,
        'quantity': quantity,
        'unit': unit,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}

/// A single meal entry logged by the user.
class MealEntry {
  final String id;
  final String userId;
  final String foodId;
  final String foodName;
  final MealType mealType;
  final double servingQuantity;
  final String servingUnit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final DateTime loggedAt;
  final String imageUrl;
  final List<MealFood> foods;

  double get totalCalories => calories;
  double get totalProtein => protein;
  double get totalCarbs => carbs;
  double get totalFat => fat;
  DateTime get date => loggedAt;

  MealEntry({
    required this.id,
    required this.userId,
    String? foodId,
    String? foodName,
    dynamic mealType = MealType.snack,
    double? servingQuantity,
    String? servingUnit,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    this.fiber = 0.0,
    DateTime? loggedAt,
    DateTime? date,
    this.imageUrl = '',
    List<MealFood>? foods,
  })  : foodId =
            foodId ?? (foods?.isNotEmpty == true ? foods!.first.foodId : ''),
        foodName = foodName ??
            (foods?.isNotEmpty == true ? foods!.first.foodName : ''),
        mealType = mealType is MealType
            ? mealType
            : MealType.fromString(mealType?.toString() ?? ''),
        servingQuantity = servingQuantity ?? 1.0,
        servingUnit = servingUnit ?? 'serving',
        calories = calories ??
            (totalCalories ??
                (foods?.fold<double>(0, (s, f) => s + f.calories) ?? 0.0)),
        protein = protein ??
            (totalProtein ??
                (foods?.fold<double>(0, (s, f) => s + f.protein) ?? 0.0)),
        carbs = carbs ??
            (totalCarbs ??
                (foods?.fold<double>(0, (s, f) => s + f.carbs) ?? 0.0)),
        fat = fat ??
            (totalFat ?? (foods?.fold<double>(0, (s, f) => s + f.fat) ?? 0.0)),
        loggedAt = loggedAt ?? (date ?? DateTime.now()),
        foods = foods ?? const [];

  factory MealEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MealEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      foodId: data['foodId'] as String? ?? '',
      foodName: data['foodName'] as String? ?? '',
      mealType: MealType.fromString(data['mealType'] as String? ?? ''),
      servingQuantity: (data['servingQuantity'] as num?)?.toDouble() ?? 1.0,
      servingUnit: data['servingUnit'] as String? ?? 'serving',
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (data['fiber'] as num?)?.toDouble() ?? 0.0,
      loggedAt: (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'foodId': foodId,
      'foodName': foodName,
      'mealType': mealType.name,
      'servingQuantity': servingQuantity,
      'servingUnit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'loggedAt': loggedAt.toIso8601String(),
      'imageUrl': imageUrl,
      'foods': foods.map((f) => f.toMap()).toList(),
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> data) {
    return MealEntry(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      foodId: data['foodId'] as String? ?? '',
      foodName: data['foodName'] as String? ?? '',
      mealType: data['mealType'] as String? ?? 'snack',
      servingQuantity: (data['servingQuantity'] as num?)?.toDouble() ?? 1.0,
      servingUnit: data['servingUnit'] as String? ?? 'serving',
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (data['fiber'] as num?)?.toDouble() ?? 0.0,
      loggedAt: data['loggedAt'] != null
          ? (DateTime.tryParse(data['loggedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      imageUrl: data['imageUrl'] as String? ?? '',
      foods: (data['foods'] as List<dynamic>?)
              ?.map((f) => MealFood(
                    foodId: f['foodId'] as String? ?? '',
                    foodName: f['foodName'] as String? ?? '',
                    quantity: (f['quantity'] as num?)?.toDouble() ?? 1.0,
                    unit: f['unit'] as String? ?? 'serving',
                    calories: (f['calories'] as num?)?.toDouble() ?? 0.0,
                    protein: (f['protein'] as num?)?.toDouble() ?? 0.0,
                    carbs: (f['carbs'] as num?)?.toDouble() ?? 0.0,
                    fat: (f['fat'] as num?)?.toDouble() ?? 0.0,
                  ))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'foodId': foodId,
      'foodName': foodName,
      'mealType': mealType.name,
      'servingQuantity': servingQuantity,
      'servingUnit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'imageUrl': imageUrl,
    };
  }

  MealEntry copyWith({
    String? id,
    String? userId,
    String? foodId,
    String? foodName,
    MealType? mealType,
    double? servingQuantity,
    String? servingUnit,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    DateTime? loggedAt,
    String? imageUrl,
  }) {
    return MealEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      mealType: mealType ?? this.mealType,
      servingQuantity: servingQuantity ?? this.servingQuantity,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      loggedAt: loggedAt ?? this.loggedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Daily nutrition summary.
class DailyNutrition {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final List<MealEntry> meals;

  const DailyNutrition({
    required this.date,
    this.totalCalories = 0.0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    this.totalFiber = 0.0,
    this.meals = const [],
  });

  factory DailyNutrition.fromMeals(DateTime date, List<MealEntry> meals) {
    return DailyNutrition(
      date: date,
      totalCalories: meals.fold(0.0, (sum, m) => sum + m.calories),
      totalProtein: meals.fold(0.0, (sum, m) => sum + m.protein),
      totalCarbs: meals.fold(0.0, (sum, m) => sum + m.carbs),
      totalFat: meals.fold(0.0, (sum, m) => sum + m.fat),
      totalFiber: meals.fold(0.0, (sum, m) => sum + m.fiber),
      meals: meals,
    );
  }
}

/// Nutrition targets for the user.
class NutritionTargets {
  final int calorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;
  final double fiberTarget;

  const NutritionTargets({
    this.calorieTarget = 2000,
    this.proteinTarget = 120.0,
    this.carbsTarget = 250.0,
    this.fatTarget = 65.0,
    this.fiberTarget = 25.0,
  });

  factory NutritionTargets.fromMap(Map<String, dynamic> map) {
    return NutritionTargets(
      calorieTarget: map['calorieTarget'] as int? ?? 2000,
      proteinTarget: (map['proteinTarget'] as num?)?.toDouble() ?? 120.0,
      carbsTarget: (map['carbsTarget'] as num?)?.toDouble() ?? 250.0,
      fatTarget: (map['fatTarget'] as num?)?.toDouble() ?? 65.0,
      fiberTarget: (map['fiberTarget'] as num?)?.toDouble() ?? 25.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calorieTarget': calorieTarget,
      'proteinTarget': proteinTarget,
      'carbsTarget': carbsTarget,
      'fatTarget': fatTarget,
      'fiberTarget': fiberTarget,
    };
  }
}
