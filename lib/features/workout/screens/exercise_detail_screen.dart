import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/exercise_model.dart';
import 'package:go_router/go_router.dart';

/// Connected Shared-Element Detail Screen for an Exercise.
/// Features seamless Hero animation from the Exercise Card.
class ExerciseDetailScreen extends StatelessWidget {
  final ExerciseModel exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
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

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Exercise Details',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image & Title Card Container with Hero Elements
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.darkCardBackground
                      : FormaColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'exercise_img_${exercise.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(
                                alpha: isDark ? 0.22 : 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: badgeColor.withValues(
                                  alpha: isDark ? 0.4 : 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: exercise.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: exercise.imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Icon(
                                    badgeIcon,
                                    size: 54,
                                    color: badgeColor,
                                  ),
                                )
                              : Icon(
                                  badgeIcon,
                                  size: 58,
                                  color: badgeColor,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Hero(
                      tag: 'exercise_title_${exercise.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          exercise.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? FormaColors.darkPrimaryText
                                : FormaColors.lightPrimaryText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            FormaColors.primaryAccent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        exercise.difficulty.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: FormaColors.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Metrics & Tags Row
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildTag(
                    context,
                    icon: Icons.accessibility_new_rounded,
                    label: exercise.primaryMuscle,
                    color: FormaColors.coralPink,
                  ),
                  _buildTag(
                    context,
                    icon: Icons.fitness_center_rounded,
                    label: exercise.equipment,
                    color: FormaColors.primaryAccent,
                  ),
                  _buildTag(
                    context,
                    icon: Icons.category_rounded,
                    label: exercise.category,
                    color: FormaColors.goldenYellow,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 3. Execution Instructions & Form Cues
              Text(
                'Form & Technique',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkPrimaryText
                      : FormaColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: isDark ? 0.2 : 0.12),
                  ),
                ),
                child: Text(
                  exercise.instructions.isNotEmpty
                      ? exercise.instructions
                      : '1. Set up with stable footing and engage core muscles.\n'
                          '2. Maintain neutral spine alignment throughout the repetition.\n'
                          '3. Control the eccentric (lowering) phase for 2-3 seconds.\n'
                          '4. Drive upward with explosive intent while preserving strict technique.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 4. Quick Action Button
              FormaBounceable(
                child: FormaButton(
                  label: 'Log This Exercise Now',
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () {
                    context.push('/workout/manual-log', extra: exercise);
                  },
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
        ],
      ),
    );
  }
}
