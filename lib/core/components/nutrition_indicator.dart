import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

class NutritionIndicator extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final String unit;
  final Color color;

  const NutritionIndicator({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    this.unit = 'g',
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? FormaColors.darkSecondaryText
                    : FormaColors.lightSecondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
            children: [
              TextSpan(
                text: '${current.toInt()}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: '/${target.toInt()}$unit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 6,
            width: double.infinity,
            color: isDark
                ? FormaColors.darkSecondaryBackground
                : FormaColors.lightSecondaryBackground,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
