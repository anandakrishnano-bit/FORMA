import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final bool isCompact;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.onToggle,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitColor = Color(habit.colorValue);

    if (isCompact) {
      return FormaBounceable(
        onTap: onTap ?? onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? FormaColors.darkCardBackground
                : FormaColors.lightCardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted
                  ? habitColor.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? habitColor.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: habitColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      // ignore: non_const_argument_for_const_parameter
                      IconData(habit.iconCodePoint,
                          fontFamily: 'MaterialIcons'),
                      color: habitColor,
                      size: 20,
                    ),
                  ),
                  FormaBounceable(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onToggle();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted ? habitColor : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted
                              ? habitColor
                              : (isDark
                                  ? FormaColors.darkSecondaryText
                                  : FormaColors.concreteGrey),
                          width: 2,
                        ),
                      ),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: isCompleted ? 1.0 : 0.0,
                        curve: Curves.elasticOut,
                        child: const Icon(Icons.check,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                habit.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return FormaBounceable(
      onTap: onTap ?? onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? (isDark
                  ? FormaColors.darkCardBackground.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.7))
              : (isDark
                  ? Color.alphaBlend(habitColor.withValues(alpha: 0.12),
                      FormaColors.darkCardBackground)
                  : Color.alphaBlend(
                      habitColor.withValues(alpha: 0.10), Colors.white)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted
                ? habitColor.withValues(alpha: 0.3)
                : habitColor.withValues(alpha: isDark ? 0.25 : 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? habitColor.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: habitColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                // ignore: non_const_argument_for_const_parameter
                IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: habitColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: isCompleted
                          ? (isDark ? Colors.white54 : Colors.black45)
                          : (isDark
                              ? FormaColors.darkPrimaryText
                              : FormaColors.lightPrimaryText),
                    ),
                    child: Text(habit.title),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (habit.description != null &&
                            habit.description!.isNotEmpty &&
                            !habit.description!.contains('HabitFrequency'))
                        ? habit.description!
                        : '${habit.frequency.displayName} • Streak: ${habit.streakCount} days',
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
            FormaBounceable(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isCompleted ? habitColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? habitColor
                        : (isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.concreteGrey),
                    width: 2,
                  ),
                  boxShadow: [
                    if (isCompleted)
                      BoxShadow(
                        color: habitColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isCompleted ? 1.0 : 0.0,
                  curve: Curves.elasticOut,
                  child: const Icon(Icons.check, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
