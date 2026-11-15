import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/food_card.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/components/animated_capsule_progress.dart';
import 'package:forma/core/components/search_field.dart';
import 'package:forma/core/components/section_header.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/nutrition_model.dart';
import 'package:forma/data/repositories/discovery_repository.dart';
import 'package:forma/data/repositories/nutrition_repository.dart';
import 'package:forma/features/nutrition/widgets/food_discovery_modal.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> _categories = [
    'All',
    'South Indian',
    'North Indian',
    'Meat',
    'Eggs',
    'Dairy',
    'Fruits',
    'Pulses',
    'Rice and Grains'
  ];

  void _showQuickAddMealSheet(BuildContext context, FoodItem food) {
    final structuredPortions = food.structuredPortions;
    PortionTier selectedTier = PortionTier.medium;
    final mediumPortion = structuredPortions.firstWhere(
      (p) => p.tier == PortionTier.medium,
      orElse: () => structuredPortions.first,
    );

    double quantity = 1.0;
    String selectedMealType = 'Lunch';
    double currentGrams = mediumPortion.gramEquivalent;
    final TextEditingController gramController =
        TextEditingController(text: '${currentGrams.toInt()}');
    final TextEditingController customLabelController = TextEditingController();

    // Fetch custom portions saved by user for this food
    List<CustomPortion> savedCustomPortions = [];
    ref
        .read(nutritionRepositoryProvider)
        .getCustomPortions(foodId: food.id)
        .then((list) {
      savedCustomPortions = list;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          final totalGrams = selectedTier == PortionTier.custom
              ? (double.tryParse(gramController.text) ?? currentGrams) *
                  quantity
              : currentGrams * quantity;

          final nutrients = food.calculateNutrientsForGrams(totalGrams);
          final calcCalories = nutrients.calories.round();
          final calcProtein = nutrients.protein.toStringAsFixed(1);
          final calcCarbs = nutrients.carbs.toStringAsFixed(1);
          final calcFat = nutrients.fat.toStringAsFixed(1);

          final selectedStructuredPortion = structuredPortions.firstWhere(
            (p) => p.tier == selectedTier,
            orElse: () => structuredPortions.first,
          );

          void showSaveCustomPortionDialog() {
            showDialog(
              context: context,
              builder: (dCtx) => AlertDialog(
                backgroundColor: isDark ? FormaColors.charcoal : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text(
                  'Save Custom Portion',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800, fontSize: 17),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Save ${totalGrams.toInt()}g as your personal serving size for ${food.name}.',
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark ? Colors.white70 : FormaColors.charcoal),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: customLabelController,
                      decoration: InputDecoration(
                        hintText: 'e.g. My regular rice bowl',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final label = customLabelController.text.trim();
                      if (label.isNotEmpty) {
                        final user = FirebaseAuth.instance.currentUser;
                        final newPortion = CustomPortion(
                          id: '',
                          userId: user?.uid ?? 'guest',
                          foodId: food.id,
                          foodName: food.name,
                          label: label,
                          gramEquivalent: totalGrams,
                          createdAt: DateTime.now(),
                        );
                        await ref
                            .read(nutritionRepositoryProvider)
                            .saveCustomPortion(newPortion);
                        savedCustomPortions.add(newPortion);
                        Navigator.of(dCtx).pop();
                        setSheetState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FormaColors.primaryAccent,
                      foregroundColor: FormaColors.charcoal,
                    ),
                    child: const Text('Save Portion',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 24 +
                  MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: FormaColors.concreteGrey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Food header with image
                  Row(
                    children: [
                      Hero(
                        tag: 'food_img_${food.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: isDark
                                ? FormaColors.darkCardBackground
                                : Colors.white,
                            child: food.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: food.imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(
                                        Icons.restaurant,
                                        color: FormaColors.concreteGrey),
                                  )
                                : const Icon(Icons.restaurant,
                                    color: FormaColors.primaryAccent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? FormaColors.darkPrimaryText
                                    : FormaColors.lightPrimaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              food.category,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: FormaColors.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Meal type selector (Breakfast, Lunch, Dinner, Snack)
                  const Text('Select Meal',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ('Breakfast', '🍳'),
                        ('Lunch', '🥗'),
                        ('Dinner', '🍲'),
                        ('Snack', '🍎'),
                      ].map((item) {
                        final isSel = selectedMealType == item.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${item.$2} ${item.$1}'),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: isSel
                                  ? FormaColors.charcoal
                                  : (isDark
                                      ? Colors.white
                                      : FormaColors.charcoal),
                            ),
                            selected: isSel,
                            selectedColor: FormaColors.primaryAccent,
                            backgroundColor: isDark
                                ? FormaColors.darkCardBackground
                                : Colors.white,
                            onSelected: (val) {
                              if (val)
                                setSheetState(() => selectedMealType = item.$1);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── PART 3: PORTION SIZE SELECTOR (Small, Medium, Large, Custom) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Portion Size',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      if (selectedTier != PortionTier.custom)
                        Text(
                          selectedStructuredPortion.unitDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FormaColors.primaryAccent,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Premium Segmented Control: Small | Medium | Large | Custom
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? FormaColors.darkCardBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : FormaColors.divider.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        PortionTier.small,
                        PortionTier.medium,
                        PortionTier.large,
                        PortionTier.custom,
                      ].map((tier) {
                        final isSel = selectedTier == tier;
                        final label = tier == PortionTier.small
                            ? 'Small'
                            : (tier == PortionTier.medium
                                ? 'Medium'
                                : (tier == PortionTier.large
                                    ? 'Large'
                                    : 'Custom'));

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setSheetState(() {
                                selectedTier = tier;
                                if (tier != PortionTier.custom) {
                                  final p = structuredPortions.firstWhere(
                                    (sp) => sp.tier == tier,
                                    orElse: () => structuredPortions.first,
                                  );
                                  currentGrams = p.gramEquivalent;
                                  gramController.text =
                                      '${p.gramEquivalent.toInt()}';
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? FormaColors.goldenYellow
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSel
                                    ? [
                                        BoxShadow(
                                          color: FormaColors.goldenYellow
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSel
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSel
                                        ? FormaColors.charcoal
                                        : (isDark
                                            ? Colors.white70
                                            : FormaColors.charcoal),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Custom Portions & Custom Gram Input
                  if (selectedTier == PortionTier.custom) ...[
                    // Saved User Custom Portions Chips (if any)
                    if (savedCustomPortions.isNotEmpty) ...[
                      const Text(
                        'Saved Custom Portions',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: savedCustomPortions.map((cp) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(
                                    '${cp.label} (${cp.gramEquivalent.toInt()}g)'),
                                backgroundColor: isDark
                                    ? FormaColors.darkCardBackground
                                    : Colors.white,
                                onPressed: () {
                                  setSheetState(() {
                                    currentGrams = cp.gramEquivalent;
                                    gramController.text =
                                        '${cp.gramEquivalent.toInt()}';
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    Row(
                      children: [
                        const Text('Weight / Volume: ',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: gramController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                            decoration: InputDecoration(
                              suffixText: food.servingUnit.isNotEmpty &&
                                      food.servingUnit != 'g'
                                  ? food.servingUnit
                                  : 'grams',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: isDark
                                  ? FormaColors.darkCardBackground
                                  : Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                            ),
                            onChanged: (val) {
                              setSheetState(() {
                                currentGrams = double.tryParse(val) ?? 100.0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.bookmark_add_outlined,
                              color: FormaColors.primaryAccent),
                          tooltip: 'Save Custom Portion',
                          onPressed: showSaveCustomPortionDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quick Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [50, 100, 150, 200, 250, 300, 400].map((w) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text('${w}g',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                              backgroundColor: isDark
                                  ? FormaColors.darkCardBackground
                                  : Colors.white,
                              onPressed: () {
                                setSheetState(() {
                                  currentGrams = w.toDouble();
                                  gramController.text = '$w';
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ] else ...[
                    // Stepper for multiple portions (e.g. 2 x Medium bowl)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Number of ${selectedStructuredPortion.label} portions:',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? FormaColors.darkCardBackground
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.remove_rounded, size: 20),
                                onPressed: quantity > 0.5
                                    ? () => setSheetState(() => quantity =
                                        (quantity - 0.5).clamp(0.5, 10.0))
                                    : null,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  quantity % 1 == 0
                                      ? '${quantity.toInt()}'
                                      : quantity.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 20),
                                onPressed: () => setSheetState(() => quantity =
                                    (quantity + 0.5).clamp(0.5, 10.0)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Calculated Dynamic Macro Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? FormaColors.darkCardBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color:
                              FormaColors.primaryAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ENERGY LOGGED',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: FormaColors.primaryAccent,
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                Text('$calcCalories kcal',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: FormaColors.primaryAccent)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: FormaColors.charcoal
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '≈ ${totalGrams.toInt()}g total',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMacroPill('Protein', '${calcProtein}g',
                                FormaColors.terracotta),
                            _buildMacroPill('Carbs', '${calcCarbs}g',
                                FormaColors.goldenYellow),
                            _buildMacroPill(
                                'Fat', '${calcFat}g', FormaColors.azure),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Primary Log Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FormaColors.charcoal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final portionUnitLabel = selectedTier ==
                                PortionTier.custom
                            ? '${totalGrams.toInt()}g'
                            : '${selectedStructuredPortion.label} (${totalGrams.toInt()}g)';

                        final meal = MealEntry(
                          id: 'meal_${DateTime.now().millisecondsSinceEpoch}',
                          userId: 'user_active',
                          loggedAt: DateTime.now(),
                          date: DateTime.now(),
                          mealType: selectedMealType,
                          foodId: food.id,
                          foodName: food.name,
                          servingQuantity: quantity,
                          servingUnit: portionUnitLabel,
                          calories: calcCalories.toDouble(),
                          protein: double.tryParse(calcProtein) ?? 0.0,
                          carbs: double.tryParse(calcCarbs) ?? 0.0,
                          fat: double.tryParse(calcFat) ?? 0.0,
                          foods: [
                            MealFood(
                              foodId: food.id,
                              foodName: food.name,
                              quantity: quantity,
                              unit: portionUnitLabel,
                              calories: calcCalories.toDouble(),
                              protein: double.tryParse(calcProtein) ?? 0.0,
                              carbs: double.tryParse(calcCarbs) ?? 0.0,
                              fat: double.tryParse(calcFat) ?? 0.0,
                            ),
                          ],
                          totalCalories: calcCalories.toDouble(),
                          totalProtein: double.tryParse(calcProtein) ?? 0.0,
                          totalCarbs: double.tryParse(calcCarbs) ?? 0.0,
                          totalFat: double.tryParse(calcFat) ?? 0.0,
                        );

                        await ref
                            .read(nutritionRepositoryProvider)
                            .logMeal(meal);
                        ref.invalidate(todayMealsProvider);

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✓ Logged "${food.name}" ($calcCalories kcal) for $selectedMealType!'),
                              backgroundColor: FormaColors.success,
                            ),
                          );
                        }
                      },
                      child: const Text('Add to Food Diary',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: FormaColors.concreteGrey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mealsAsync = ref.watch(todayMealsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('Nutrition',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: FormaColors.primaryAccent,
          onRefresh: () async {
            ref.invalidate(todayMealsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. GENUINE CALORIE & MACRO OVERVIEW
                mealsAsync.when(
                  data: (meals) {
                    final totalCalories = meals
                        .fold<double>(0, (s, m) => s + m.totalCalories)
                        .toInt();
                    final totalProtein =
                        meals.fold<double>(0, (s, m) => s + m.totalProtein);
                    final totalCarbs =
                        meals.fold<double>(0, (s, m) => s + m.totalCarbs);
                    final totalFat =
                        meals.fold<double>(0, (s, m) => s + m.totalFat);
                    const targetCalories = 2500;

                    return Column(
                      children: [
                        // Prominent Editorial Calorie Display (Reference Image 2)
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '$totalCalories',
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                  color: isDark
                                      ? FormaColors.darkPrimaryText
                                      : FormaColors.lightPrimaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Calories logged today of 2,500 target',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Signature 4-Capsule Macro Visualization (Reference Image 2)
                        AnimatedCapsuleChart(
                          height: 140,
                          bars: [
                            CapsuleBarData(
                              label: 'Calories',
                              percentage: (totalCalories / targetCalories)
                                  .clamp(0.0, 1.0),
                              fillColor: FormaColors.goldenYellow,
                            ),
                            CapsuleBarData(
                              label: 'Protein',
                              percentage:
                                  (totalProtein / 160.0).clamp(0.0, 1.0),
                              fillColor: FormaColors.coralPink,
                            ),
                            CapsuleBarData(
                              label: 'Carbs',
                              percentage: (totalCarbs / 280.0).clamp(0.0, 1.0),
                              fillColor: FormaColors.icyBlue,
                            ),
                            CapsuleBarData(
                              label: 'Fats',
                              percentage: (totalFat / 65.0).clamp(0.0, 1.0),
                              fillColor: FormaColors.sage,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 28),

                // 2. MEALS LOGGED TODAY
                FormaSectionHeader(
                  title: 'Meals Logged Today',
                  actionLabel: '+ Search Food',
                  onAction: () async {
                    final food = await showModalBottomSheet<FoodItem>(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const FoodDiscoveryModal(),
                    );
                    if (food != null && mounted) {
                      _showQuickAddMealSheet(context, food);
                    }
                  },
                ),
                const SizedBox(height: 14),

                mealsAsync.when(
                  data: (meals) {
                    if (meals.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? FormaColors.darkCardBackground
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.restaurant_outlined,
                                  size: 36, color: FormaColors.concreteGrey),
                              const SizedBox(height: 10),
                              const Text(
                                'No Meals Logged Today',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Search and tap any food below to log breakfast, lunch or snacks.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: meals.map((meal) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? FormaColors.darkCardBackground
                                : FormaColors.lightCardBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    meal.mealType.displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? FormaColors.darkPrimaryText
                                          : FormaColors.lightPrimaryText,
                                    ),
                                  ),
                                  Text(
                                    '${meal.totalCalories.toInt()} kcal',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: FormaColors.primaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                meal.foods.isNotEmpty
                                    ? meal.foods
                                        .map((f) =>
                                            '${f.quantity % 1 == 0 ? f.quantity.toInt() : f.quantity}x ${f.foodName} (${f.unit})')
                                        .join(', ')
                                    : '${meal.servingQuantity % 1 == 0 ? meal.servingQuantity.toInt() : meal.servingQuantity}x ${meal.foodName} (${meal.servingUnit})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'P: ${meal.totalProtein.toStringAsFixed(1)}g',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: FormaColors.terracotta),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'C: ${meal.totalCarbs.toStringAsFixed(1)}g',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: FormaColors.goldenYellow),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'F: ${meal.totalFat.toStringAsFixed(1)}g',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: FormaColors.azure),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 24),

                // 3. UNIFIED FOOD SEARCH & EXPLORER
                const FormaSectionHeader(
                  title: 'Food Library & Discovery',
                ),
                const SizedBox(height: 12),
                FormaSearchField(
                  controller: _searchController,
                  hintText: 'Search food (e.g. Idli, Paneer, Oats)...',
                  onChanged: (query) {
                    setState(() => _searchQuery = query.trim());
                    ref.read(foodDiscoveryProvider.notifier).search(query);
                  },
                ),
                const SizedBox(height: 12),

                // If user typed in search bar: show unified search results
                if (_searchQuery.isNotEmpty) ...[
                  // Inline "Search Online with AI" action pill
                  FormaBounceable(
                    onTap: () {
                      ref
                          .read(foodDiscoveryProvider.notifier)
                          .triggerOnlineSearch(_searchQuery);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? FormaColors.terracottaDark
                            : FormaColors.terracottaPastel,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                FormaColors.terracotta.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.travel_explore_rounded,
                              size: 18, color: FormaColors.terracotta),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search online library for "$_searchQuery"',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FormaColors.terracotta,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: FormaColors.terracotta),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Inline Online Loading State
                  Consumer(
                    builder: (context, ref, _) {
                      final discoveryState = ref.watch(foodDiscoveryProvider);

                      if (discoveryState.status == DiscoveryStatus.searching) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? FormaColors.charcoal
                                : FormaColors.warmCream,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: FormaColors.primaryAccent
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      FormaColors.primaryAccent),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  discoveryState.statusMessage.isNotEmpty
                                      ? discoveryState.statusMessage
                                      : 'Searching food database...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? FormaColors.darkPrimaryText
                                        : FormaColors.lightPrimaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (discoveryState.discoveredResults.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color:
                                    FormaColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'VERIFIED ONLINE RESULTS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: FormaColors.success,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...discoveryState.discoveredResults.map((food) {
                              return FoodCard(
                                food: food,
                                onAdd: () {
                                  ref
                                      .read(foodDiscoveryProvider.notifier)
                                      .approveAndSaveFood(food);
                                  _showQuickAddMealSheet(context, food);
                                },
                              );
                            }),
                            const SizedBox(height: 14),
                          ],
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),

                  // Local Matches
                  FutureBuilder<List<FoodItem>>(
                    future: ref
                        .read(nutritionRepositoryProvider)
                        .searchFoods(_searchQuery),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final localFoods = snapshot.data!;

                      if (localFoods.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No local matches. Tap "Search online library" above.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? FormaColors.darkSecondaryText
                                    : FormaColors.lightSecondaryText,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: localFoods.map((f) {
                          return FoodCard(
                            food: f,
                            onAdd: () => _showQuickAddMealSheet(context, f),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ] else ...[
                  // Category filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? FormaColors.primaryAccent
                                  : (isDark
                                      ? FormaColors.darkCardBackground
                                      : FormaColors.lightCardBackground),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? FormaColors.primaryAccent
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? FormaColors.charcoal
                                    : (isDark
                                        ? FormaColors.darkSecondaryText
                                        : FormaColors.lightSecondaryText),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 18),
                  FutureBuilder<List<FoodItem>>(
                    future: ref
                        .read(nutritionRepositoryProvider)
                        .searchFoods('', category: _selectedCategory),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final foods = snapshot.data!;
                      return Column(
                        children: foods.map((f) {
                          return FoodCard(
                            food: f,
                            onAdd: () => _showQuickAddMealSheet(context, f),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
