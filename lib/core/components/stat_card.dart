import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

class FormaStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? color;
  final Color? iconColor;

  const FormaStatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = color ??
        (isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              Icon(
                icon,
                size: 20,
                color: iconColor ?? FormaColors.primaryAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  text: value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
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
        ],
      ),
    );
  }
}
