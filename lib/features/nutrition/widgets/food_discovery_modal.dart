import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/components/food_card.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/components/search_field.dart';
import 'package:forma/core/components/section_header.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/repositories/discovery_repository.dart';

class FoodDiscoveryModal extends ConsumerStatefulWidget {
  const FoodDiscoveryModal({super.key});

  @override
  ConsumerState<FoodDiscoveryModal> createState() => _FoodDiscoveryModalState();
}

class _FoodDiscoveryModalState extends ConsumerState<FoodDiscoveryModal> {
  final TextEditingController _controller = TextEditingController();
  int _selectedFilterIndex = 0; // 0: All, 1: General Foods, 2: Branded Products

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(foodDiscoveryProvider);

    final filteredInternal = state.internalResults.where((f) {
      if (_selectedFilterIndex == 1) return !f.isBranded;
      if (_selectedFilterIndex == 2) return f.isBranded;
      return true;
    }).toList();

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: SafeArea(
        bottom: true,
        child: Container(
          height: mediaQuery.size.height * 0.85,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? FormaColors.darkBackground
                : FormaColors.lightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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
              Text(
                'Food & Nutrition Search',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 14),

              // Search Field
              FormaSearchField(
                controller: _controller,
                hintText: 'Search foods (e.g. Pizza, Oats, Chicken)...',
                onChanged: (val) {
                  setState(() {});
                  if (val.trim().isNotEmpty) {
                    ref.read(foodDiscoveryProvider.notifier).search(val);
                  }
                },
              ),

              const SizedBox(height: 12),

              // 3-way Filter toggle: All / General Foods / Branded Products
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(0, 'All Foods', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'General Foods (Whole)', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Branded Products', isDark),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (_controller.text.trim().isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    ref
                        .read(foodDiscoveryProvider.notifier)
                        .triggerOnlineSearch(_controller.text.trim());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? FormaColors.terracottaDark
                          : FormaColors.terracottaPastel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: FormaColors.terracotta.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.travel_explore_rounded,
                            size: 18, color: FormaColors.terracotta),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search online & subcategories for "${_controller.text.trim()}"',
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
              ],

              // Status & Results
              if (state.status == DiscoveryStatus.searching)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              FormaColors.primaryAccent),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Searching for results...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state.status == DiscoveryStatus.notFound)
                Expanded(
                  child: Center(
                    child: Text(
                      state.statusMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ),
                )
              else ...[
                if (filteredInternal.isNotEmpty) ...[
                  FormaSectionHeader(
                    title: _selectedFilterIndex == 1
                        ? 'General & Whole Foods'
                        : (_selectedFilterIndex == 2
                            ? 'Branded Products'
                            : 'From FORMA Food Database'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredInternal.length,
                      itemBuilder: (context, idx) {
                        final food = filteredInternal[idx];
                        return FoodCard(
                          food: food,
                          onAdd: () {
                            Navigator.of(context).pop(food);
                          },
                        );
                      },
                    ),
                  ),
                ] else if (state.discoveredResults.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const FormaSectionHeader(title: 'Discovered Results'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              FormaColors.primaryAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Verified Data',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: FormaColors.goldenYellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.discoveredResults.length,
                      itemBuilder: (context, idx) {
                        final food = state.discoveredResults[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? FormaColors.darkCardBackground
                                : FormaColors.lightCardBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: FormaColors.primaryAccent
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      food.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? FormaColors.darkPrimaryText
                                            : FormaColors.lightPrimaryText,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${food.calories.toInt()} kcal',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: FormaColors.primaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${food.protein.toInt()}g Protein • ${food.carbs.toInt()}g Carbs • ${food.fat.toInt()}g Fat (per ${food.servingSize.toInt()}${food.servingUnit})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FormaButton(
                                    label: 'Save & Log',
                                    onPressed: () {
                                      ref
                                          .read(foodDiscoveryProvider.notifier)
                                          .approveAndSaveFood(food);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Added "${food.name}" to FORMA database!')),
                                      );
                                      Navigator.of(context).pop(food);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Center(
                      child: Text('Type 3+ letters to search...'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilterIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? FormaColors.goldenYellow
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? FormaColors.charcoal
                : (isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText),
          ),
        ),
      ),
    );
  }
}
