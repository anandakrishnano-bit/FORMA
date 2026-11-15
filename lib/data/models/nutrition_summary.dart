/// Daily nutrition summary for the home dashboard.
class NutritionSummary {
  final int caloriesConsumed;
  final int caloriesGoal;
  final int proteinConsumed;
  final int proteinGoal;
  final int waterGlasses;
  final int waterGoal;
  final int carbsConsumed;
  final int carbsGoal;
  final int fatConsumed;
  final int fatGoal;

  const NutritionSummary({
    required this.caloriesConsumed,
    required this.caloriesGoal,
    required this.proteinConsumed,
    required this.proteinGoal,
    required this.waterGlasses,
    required this.waterGoal,
    this.carbsConsumed = 0,
    this.carbsGoal = 250,
    this.fatConsumed = 0,
    this.fatGoal = 70,
  });

  double get caloriesProgress =>
      caloriesGoal > 0 ? (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0) : 0;

  double get proteinProgress =>
      proteinGoal > 0 ? (proteinConsumed / proteinGoal).clamp(0.0, 1.0) : 0;

  double get waterProgress =>
      waterGoal > 0 ? (waterGlasses / waterGoal).clamp(0.0, 1.0) : 0;

  factory NutritionSummary.fromJson(Map<String, dynamic> json) {
    return NutritionSummary(
      caloriesConsumed: json['caloriesConsumed'] as int,
      caloriesGoal: json['caloriesGoal'] as int,
      proteinConsumed: json['proteinConsumed'] as int,
      proteinGoal: json['proteinGoal'] as int,
      waterGlasses: json['waterGlasses'] as int,
      waterGoal: json['waterGoal'] as int,
      carbsConsumed: json['carbsConsumed'] as int? ?? 0,
      carbsGoal: json['carbsGoal'] as int? ?? 250,
      fatConsumed: json['fatConsumed'] as int? ?? 0,
      fatGoal: json['fatGoal'] as int? ?? 70,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caloriesConsumed': caloriesConsumed,
      'caloriesGoal': caloriesGoal,
      'proteinConsumed': proteinConsumed,
      'proteinGoal': proteinGoal,
      'waterGlasses': waterGlasses,
      'waterGoal': waterGoal,
      'carbsConsumed': carbsConsumed,
      'carbsGoal': carbsGoal,
      'fatConsumed': fatConsumed,
      'fatGoal': fatGoal,
    };
  }
}
