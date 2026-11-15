import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/workout_model.dart';
import 'package:forma/features/workout/screens/workout_execution_screen.dart';

/// Asymmetric Feature Hero Card (Reference Image 2 Fidelity + Container Transform)
///
/// Composes an intentional asymmetric layout:
/// - Wide Hero Card (Flex 7): Features today's primary routine with OpenContainer morphing.
/// - Tall Vertical Accent Card (Flex 3): Features daily hydration/recovery metrics.
class AsymmetricFeatureHero extends StatelessWidget {
  final WorkoutModel? workout;
  final int waterMl;
  final int targetWaterMl;
  final VoidCallback onSecondaryTap;

  const AsymmetricFeatureHero({
    super.key,
    required this.workout,
    this.waterMl = 2400,
    this.targetWaterMl = 3000,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routine = workout ??
        WorkoutModel(
          id: 'push_hypertrophy',
          userId: 'default',
          name: 'Push Day Hypertrophy',
          targetMuscleGroups: ['Chest', 'Shoulders', 'Triceps'],
          estimatedMinutes: 55,
          exercises: const [],
        );

    final waterFraction = (waterMl / targetWaterMl).clamp(0.0, 1.0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Wide Feature Card (Morphs into Workout Execution via OpenContainer)
          Expanded(
            flex: 7,
            child: OpenContainer(
              closedElevation: 0,
              openElevation: 0,
              closedColor: Colors.transparent,
              openColor: isDark
                  ? FormaColors.darkBackground
                  : FormaColors.lightBackground,
              transitionDuration: const Duration(milliseconds: 460),
              transitionType: ContainerTransitionType.fadeThrough,
              closedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              closedBuilder: (context, openContainer) {
                return Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color:
                                  FormaColors.charcoal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "TODAY'S FOCUS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: FormaColors.charcoal,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            routine.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.4,
                              color: FormaColors.charcoal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${routine.estimatedMinutes} min • ${routine.targetMuscleGroups.take(2).join(', ')}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  FormaColors.charcoal.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: FormaColors.charcoal,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Start',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              openBuilder: (context, _) {
                return WorkoutExecutionScreen(workout: routine);
              },
            ),
          ),

          const SizedBox(width: 12),

          // 2. Narrow Asymmetric Partner Card (Hydration / Consistency Capsule)
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onSecondaryTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      isDark ? FormaColors.charcoal : const Color(0xFFE8E4DC),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hydration',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Vertical capsule progress indicator matching Reference 2 & 3
                    Expanded(
                      child: Container(
                        width: 28,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white60,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: waterFraction,
                          child: Container(
                            decoration: BoxDecoration(
                              color: FormaColors.icyBlue,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Text(
                          '${(waterMl / 1000).toStringAsFixed(1)}L',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? FormaColors.darkPrimaryText
                                : FormaColors.lightPrimaryText,
                          ),
                        ),
                        Text(
                          'of ${(targetWaterMl / 1000).toStringAsFixed(1)}L',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
