import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

class MuscleGroupSelector extends StatelessWidget {
  final List<String> selectedGroups;
  final ValueChanged<List<String>> onChanged;

  static const List<Map<String, dynamic>> muscleGroups = [
    {'name': 'Chest', 'icon': Icons.fitness_center},
    {'name': 'Back', 'icon': Icons.accessibility_new},
    {'name': 'Shoulders', 'icon': Icons.shield},
    {'name': 'Biceps', 'icon': Icons.sports_gymnastics},
    {'name': 'Triceps', 'icon': Icons.sports_mma},
    {'name': 'Forearms', 'icon': Icons.pan_tool},
    {'name': 'Quadriceps', 'icon': Icons.directions_run},
    {'name': 'Hamstrings', 'icon': Icons.airline_seat_legroom_extra},
    {'name': 'Glutes', 'icon': Icons.accessibility},
    {'name': 'Calves', 'icon': Icons.skateboarding},
    {'name': 'Abdominals', 'icon': Icons.grid_view},
    {'name': 'Core', 'icon': Icons.adjust},
  ];

  const MuscleGroupSelector({
    super.key,
    required this.selectedGroups,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: muscleGroups.map((group) {
        final name = group['name'] as String;
        final icon = group['icon'] as IconData;
        final isSelected = selectedGroups.contains(name);

        return GestureDetector(
          onTap: () {
            final updated = List<String>.from(selectedGroups);
            if (isSelected) {
              updated.remove(name);
            } else {
              updated.add(name);
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? FormaColors.primaryAccent
                  : (isDark
                      ? FormaColors.darkCardBackground
                      : FormaColors.lightCardBackground),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? FormaColors.primaryAccent
                    : (isDark
                        ? FormaColors.charcoal
                        : FormaColors.concreteGrey.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? FormaColors.charcoal
                      : (isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText),
                ),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? FormaColors.charcoal
                        : (isDark
                            ? FormaColors.darkPrimaryText
                            : FormaColors.lightPrimaryText),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
