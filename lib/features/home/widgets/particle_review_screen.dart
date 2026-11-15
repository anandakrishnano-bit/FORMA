import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/data/models/daily_summary_model.dart';

/// Connected Detail Screen for Daily Energy & Activity Review.
///
/// Features seamless Hero morph animation from DailyEnergyRingsWidget on Home.
/// Zero particle dissolve physics — pure 60fps connected shared elements.
class DailyReviewDetailScreen extends StatelessWidget {
  final DailySummary summary;

  const DailyReviewDetailScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;

    final steps = summary.steps;
    const stepTarget = 10000;
    final stepFraction = (steps / stepTarget).clamp(0.0, 1.0);
    final burned = summary.activeCalories.toInt();
    final consumed = summary.consumedCalories.toInt();
    final netCalories = burned - consumed;
    final hasScore = summary.hasSufficientData && summary.energyScore != null;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryTextColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Daily Energy Review',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Energy Rings & Score Card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : FormaColors.divider.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Score pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: hasScore
                            ? FormaColors.goldenYellow.withValues(alpha: 0.2)
                            : (isDark ? Colors.white12 : Colors.black12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasScore
                            ? 'ENERGY SCORE ${summary.energyScore}/100'
                            : 'DATA PENDING',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: hasScore
                              ? FormaColors.goldenYellow
                              : (isDark
                                  ? FormaColors.darkSecondaryText
                                  : FormaColors.lightSecondaryText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Rings circular graphic (Shared Hero Morph)
                    Hero(
                      tag: 'daily_energy_rings_visual',
                      flightShuttleBuilder: (flightContext, animation,
                          flightDirection, fromHeroContext, toHeroContext) {
                        return Material(
                          color: Colors.transparent,
                          child: flightDirection == HeroFlightDirection.push
                              ? toHeroContext.widget
                              : fromHeroContext.widget,
                        );
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 170,
                          height: 170,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(170, 170),
                                painter: _ReviewRingsPainter(
                                  outerFraction: stepFraction,
                                  middleFraction: burned > 0
                                      ? (burned / 600.0).clamp(0.0, 1.0)
                                      : 0.0,
                                  innerFraction: hasScore
                                      ? (summary.energyScore! / 100.0)
                                          .clamp(0.0, 1.0)
                                      : 0.0,
                                  isDark: isDark,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    hasScore ? '${summary.energyScore}' : '--',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: hasScore ? 42 : 36,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.2,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    hasScore ? 'Calculated' : 'Unscored',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: hasScore
                                          ? FormaColors.primaryAccent
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.black38),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      summary.scoringRationale,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: secondaryTextColor),
                    ),
                    if (summary.missingSources.isNotEmpty && !hasScore) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: summary.missingSources.map((source) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 12, color: secondaryTextColor),
                                const SizedBox(width: 4),
                                Text(
                                  source,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Metrics Breakdown Cards (Pillars)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.directions_walk_rounded,
                      iconColor: FormaColors.goldenYellow,
                      label: 'Step Target',
                      value: '$steps',
                      target: '/ 10,000 steps',
                      percent: stepFraction,
                      cardBg: cardBg,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: FormaColors.coralPink,
                      label: 'Active Burn',
                      value: '$burned',
                      target: 'kcal burned',
                      percent: (burned / 600.0).clamp(0.0, 1.0),
                      cardBg: cardBg,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.restaurant_rounded,
                      iconColor: FormaColors.terracotta,
                      label: 'Nutrition In',
                      value: '$consumed',
                      target: 'kcal consumed',
                      percent: (consumed / 2500.0).clamp(0.0, 1.0),
                      cardBg: cardBg,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.water_drop_rounded,
                      iconColor: FormaColors.azure,
                      label: 'Hydration',
                      value: '${summary.waterMl} ml',
                      target: '/ 3,000 ml target',
                      percent: (summary.waterMl / 3000.0).clamp(0.0, 1.0),
                      cardBg: cardBg,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Net Caloric Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : FormaColors.divider.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (netCalories >= 0
                                ? FormaColors.success
                                : FormaColors.coralPink)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        netCalories >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: netCalories >= 0
                            ? FormaColors.success
                            : FormaColors.coralPink,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net Daily Balance: ${netCalories > 0 ? "+" : ""}$netCalories kcal',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            netCalories > 0
                                ? 'Active caloric expenditure exceeded intake.'
                                : 'Fuel intake met training energy demands.',
                            style: TextStyle(
                                fontSize: 12, color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Return Button
              FormaBounceable(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: FormaColors.goldenYellow.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: FormaColors.charcoal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String target,
    required double percent,
    required Color cardBg,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : FormaColors.divider.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? FormaColors.darkPrimaryText
                  : FormaColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            target,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? FormaColors.darkSecondaryText
                  : FormaColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor:
                  isDark ? Colors.white10 : const Color(0xFFEEEAE0),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the 3 concentric rings in the review screen
class _ReviewRingsPainter extends CustomPainter {
  final double outerFraction;
  final double middleFraction;
  final double innerFraction;
  final bool isDark;

  _ReviewRingsPainter({
    required this.outerFraction,
    required this.middleFraction,
    required this.innerFraction,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 9.0;
    const ringSpacing = 13.0;

    final outerRadius = (size.width / 2) - strokeWidth;
    final middleRadius = outerRadius - ringSpacing;
    final innerRadius = middleRadius - ringSpacing;

    _drawArc(canvas, center, outerRadius, outerFraction, strokeWidth,
        FormaColors.goldenYellow);
    _drawArc(canvas, center, middleRadius, middleFraction, strokeWidth,
        FormaColors.coralPink);
    _drawArc(canvas, center, innerRadius, innerFraction, strokeWidth,
        FormaColors.azure);
  }

  void _drawArc(Canvas canvas, Offset center, double radius, double fraction,
      double width, Color color) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.15 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -1.5708, fraction * 2 * 3.14159, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ReviewRingsPainter oldDelegate) => false;
}

/// Backwards compatibility alias
typedef ParticleReviewScreen = DailyReviewDetailScreen;
