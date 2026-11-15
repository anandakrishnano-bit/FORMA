import 'package:flutter/material.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';

class WorkoutSetEditor extends StatelessWidget {
  final int setNumber;
  final double weight;
  final int reps;
  final bool isCompleted;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<bool> onCompletedChanged;

  const WorkoutSetEditor({
    super.key,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.isCompleted,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onCompletedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCompleted
            ? (isDark ? FormaColors.charcoal : FormaColors.warmCream)
            : (isDark
                ? FormaColors.darkCardBackground
                : FormaColors.lightCardBackground),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? FormaColors.success.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? FormaColors.darkSecondaryBackground
                  : FormaColors.lightSecondaryBackground,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$setNumber',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? FormaColors.darkPrimaryText
                    : FormaColors.lightPrimaryText,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Weight section
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: () {
                    if (weight > 0) onWeightChanged(weight - 2.5);
                  },
                ),
                Text(
                  '${weight.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () => onWeightChanged(weight + 2.5),
                ),
              ],
            ),
          ),
          // Reps section
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: () {
                    if (reps > 1) onRepsChanged(reps - 1);
                  },
                ),
                Text(
                  '$reps reps',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () => onRepsChanged(reps + 1),
                ),
              ],
            ),
          ),
          // Complete button with tactile bounce animation & checkmark pop
          FormaBounceable(
            onTap: () {
              onCompletedChanged(!isCompleted);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isCompleted ? FormaColors.success : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? FormaColors.success
                      : FormaColors.concreteGrey,
                  width: 2,
                ),
                boxShadow: [
                  if (isCompleted)
                    BoxShadow(
                      color: FormaColors.success.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isCompleted ? 1.0 : 0.0,
                curve: Curves.elasticOut,
                child: const Icon(Icons.check_rounded,
                    size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
