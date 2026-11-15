import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

class FormaProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final String? label;
  final bool showPercentage;

  const FormaProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
    this.label,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? FormaColors.primaryAccent;
    final bg = backgroundColor ??
        (isDark
            ? FormaColors.darkSecondaryBackground
            : FormaColors.lightSecondaryBackground);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '${(clamped * 100).toInt()}%',
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
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            width: double.infinity,
            color: bg,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
