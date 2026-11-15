import 'package:flutter/material.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/daily_summary_model.dart';
import 'package:go_router/go_router.dart';

class DailySummaryCard extends StatelessWidget {
  final DailySummary summary;

  const DailySummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FormaBounceable(
      onTap: () => context.push('/trainer'),
      child: Hero(
        tag: 'daily_summary_card_hero',
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: FormaColors.primaryAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: FormaColors.primaryAccent
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wb_twilight_rounded,
                              size: 18,
                              color: FormaColors.goldenYellow,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Your day in review',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? FormaColors.darkPrimaryText
                                    : FormaColors.lightPrimaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Evening',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  summary.overview,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 16),
                _buildItem(
                  context,
                  icon: Icons.fitness_center_rounded,
                  label: 'Workout',
                  text: summary.workoutSummary,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildItem(
                  context,
                  icon: Icons.restaurant_rounded,
                  label: 'Food',
                  text: summary.nutritionSummary,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildItem(
                  context,
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Habits',
                  text: summary.habitsSummary,
                  isDark: isDark,
                ),
                if (summary.suggestionForTomorrow.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? FormaColors.darkSecondaryBackground
                              : Colors.white)
                          .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: FormaColors.goldenYellow,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'For tomorrow',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? FormaColors.darkPrimaryText
                                      : FormaColors.lightPrimaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                summary.suggestionForTomorrow,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? FormaColors.darkSecondaryText
                                      : FormaColors.lightSecondaryText,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String text,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: FormaColors.primaryAccent),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: isDark
                    ? FormaColors.darkPrimaryText
                    : FormaColors.lightPrimaryText,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: text,
                  style: TextStyle(
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
