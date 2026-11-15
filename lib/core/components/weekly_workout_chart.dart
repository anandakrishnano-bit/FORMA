import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

class WeeklyWorkoutChart extends StatelessWidget {
  final List<double> weeklyHours; // 7 days (Mon - Sun)

  const WeeklyWorkoutChart({
    super.key,
    required this.weeklyHours,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return AspectRatio(
      aspectRatio: 1.8,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 2.5,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor:
                  isDark ? FormaColors.charcoal : FormaColors.warmCream,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY} hrs',
                  TextStyle(
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= weekDays.length)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      weekDays[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(weeklyHours.length, (i) {
            final val = weeklyHours[i];
            final isHighlight = i == 4; // e.g. Friday active
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: isHighlight
                      ? FormaColors.primaryAccent
                      : (isDark ? FormaColors.charcoal : FormaColors.icyBlue),
                  width: 18,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 2.5,
                    color: isDark
                        ? FormaColors.darkSecondaryBackground
                        : FormaColors.lightSecondaryBackground,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
