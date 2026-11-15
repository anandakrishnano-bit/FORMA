import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

/// Animated Capsule Bar Chart Item (Reference Image 2 Fidelity)
///
/// Models the signature tall capsule bar from Reference 2:
/// - Rounded pill-shaped track.
/// - Smooth tween-animated fill.
/// - Percentage pill tag inside or at the base.
/// - Label underneath.
class CapsuleBarData {
  final String label;
  final double percentage; // 0.0 to 1.0
  final Color fillColor;

  const CapsuleBarData({
    required this.label,
    required this.percentage,
    required this.fillColor,
  });
}

class AnimatedCapsuleChart extends StatelessWidget {
  final List<CapsuleBarData> bars;
  final double height;

  const AnimatedCapsuleChart({
    super.key,
    required this.bars,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: bars.map((bar) {
          final pctInt = (bar.percentage * 100).round();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: height,
                width: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF0ECE4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(
                        begin: 0.0, end: bar.percentage.clamp(0.0, 1.0)),
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        heightFactor: value,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: bar.fillColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: bar.fillColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.topCenter,
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            '$pctInt%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: FormaColors.charcoal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                bar.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
