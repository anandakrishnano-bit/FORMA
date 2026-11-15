import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/exercise_model.dart';

class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final Widget? trailing;
  final bool isGrid;
  final String? heroTagPrefix;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.onTap,
    this.onLog,
    this.trailing,
    this.isGrid = false,
    this.heroTagPrefix,
  });

  Color _getMuscleColor(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('chest')) return FormaColors.terracotta;
    if (m.contains('back')) return FormaColors.azure;
    if (m.contains('shoulder')) return FormaColors.goldenYellow;
    if (m.contains('quad') ||
        m.contains('leg') ||
        m.contains('glute') ||
        m.contains('hamstring') ||
        m.contains('calf')) {
      return FormaColors.sage;
    }
    if (m.contains('bicep') || m.contains('tricep') || m.contains('arm'))
      return FormaColors.lavender;
    return FormaColors.primaryAccent;
  }

  IconData _getMuscleIcon(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('chest')) return Icons.fitness_center_rounded;
    if (m.contains('back')) return Icons.sports_gymnastics_rounded;
    if (m.contains('shoulder')) return Icons.accessibility_new_rounded;
    if (m.contains('quad') ||
        m.contains('leg') ||
        m.contains('glute') ||
        m.contains('hamstring')) {
      return Icons.directions_run_rounded;
    }
    if (m.contains('bicep') || m.contains('tricep') || m.contains('arm'))
      return Icons.fitness_center_rounded;
    return Icons.fitness_center_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = _getMuscleColor(exercise.primaryMuscle);
    final badgeIcon = _getMuscleIcon(exercise.primaryMuscle);

    final prefix = heroTagPrefix ?? 'exercise';

    Widget imageWidget = Hero(
      tag: '${prefix}_img_${exercise.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: isDark ? 0.22 : 0.14),
            border: Border.all(
              color: badgeColor.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: exercise.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: exercise.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: Icon(badgeIcon, color: badgeColor, size: 28),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(badgeIcon, color: badgeColor, size: 28),
                  ),
                )
              : Center(
                  child: Icon(
                    badgeIcon,
                    color: badgeColor,
                    size: 32,
                  ),
                ),
        ),
      ),
    );

    Widget titleWidget = Hero(
      tag: '${prefix}_title_${exercise.id}',
      child: Material(
        color: Colors.transparent,
        child: Text(
          exercise.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark
                ? FormaColors.darkPrimaryText
                : FormaColors.lightPrimaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    return FormaBounceable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? FormaColors.darkCardBackground
              : FormaColors.lightCardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            imageWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.primaryMuscle} • ${exercise.equipment}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                  if (exercise.difficulty.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            badgeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exercise.difficulty.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                (onLog != null
                    ? TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          backgroundColor:
                              FormaColors.primaryAccent.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: onLog,
                        icon: const Icon(Icons.add_rounded,
                            size: 16, color: FormaColors.primaryAccent),
                        label: const Text(
                          'Log',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: FormaColors.primaryAccent,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                        color: FormaColors.concreteGrey,
                      )),
          ],
        ),
      ),
    );
  }
}
