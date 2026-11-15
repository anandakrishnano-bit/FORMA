import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/daily_summary_model.dart';
import 'package:forma/features/home/widgets/particle_review_screen.dart';

/// Interactive Apple Watch & Withings-inspired circular activity dashboard.
///
/// Features:
/// - Expressive Daily Energy Score (1-100)
/// - Surrounding organic radiating particle ring with gentle breathing animation
/// - Concentric activity progress rings (Steps, Active Minutes, Calories Burned)
/// - Daily spend vs consumed calorie balance
/// - 3 pastel summary capsules (Activity, Body, Heart)
/// - Tap to trigger the cinematic particle-to-review transition!
class DailyEnergyRingsWidget extends StatefulWidget {
  final DailySummary summary;
  final VoidCallback? onReviewOpened;

  const DailyEnergyRingsWidget({
    super.key,
    required this.summary,
    this.onReviewOpened,
  });

  @override
  State<DailyEnergyRingsWidget> createState() => _DailyEnergyRingsWidgetState();
}

class _DailyEnergyRingsWidgetState extends State<DailyEnergyRingsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openEnergyDetail(BuildContext context) {
    widget.onReviewOpened?.call();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
        transitionDuration: const Duration(milliseconds: 340),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return DailyReviewDetailScreen(summary: widget.summary);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: fadeAnim,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = widget.summary;

    final steps = summary.steps;
    const stepTarget = 10000;
    final stepFraction = (steps / stepTarget).clamp(0.0, 1.0);

    final burned = summary.activeCalories.toInt();
    final consumed = summary.consumedCalories.toInt();
    final netCalories = burned - consumed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkCardBackground
            : FormaColors.lightCardBackground,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              FormaColors.primaryAccent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'DAILY ENERGY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: FormaColors.charcoal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to review',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Health & Energy Score',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, size: 20),
                onPressed: () => _openEnergyDetail(context),
                tooltip: 'Open Day in Review',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Central Circular Visual with Rings and Connected Hero Morph
          GestureDetector(
            onTap: () => _openEnergyDetail(context),
            child: Hero(
              tag: 'daily_energy_rings_visual',
              flightShuttleBuilder: (flightContext, animation, flightDirection,
                  fromHeroContext, toHeroContext) {
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
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Concentric Progress Arcs (Steps, Burn, Consistency)
                      CustomPaint(
                        size: const Size(190, 190),
                        painter: _ConcentricRingsPainter(
                          outerFraction: stepFraction,
                          middleFraction: burned > 0
                              ? (burned / 600.0).clamp(0.0, 1.0)
                              : 0.0,
                          innerFraction: summary.hasSufficientData &&
                                  summary.energyScore != null
                              ? (summary.energyScore! / 100.0).clamp(0.0, 1.0)
                              : 0.0,
                          isDark: isDark,
                        ),
                      ),

                      // Score Center Badge
                      Container(
                        width: 125,
                        height: 125,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? FormaColors.charcoal : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.35 : 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              summary.hasSufficientData &&
                                      summary.energyScore != null
                                  ? '${summary.energyScore}'
                                  : '--',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: summary.hasSufficientData &&
                                        summary.energyScore != null
                                    ? 46
                                    : 38,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                color: isDark
                                    ? FormaColors.darkPrimaryText
                                    : FormaColors.lightPrimaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary.hasSufficientData
                                  ? 'out of 100'
                                  : 'No data yet',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
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
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3 Pastel Summary Capsules (Activity, Body, Vitals)
          Row(
            children: [
              // 1. Activity (Steps / Active)
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2E2616)
                        : const Color(0xFFFFF6E5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.directions_walk_rounded,
                          color: FormaColors.goldenYellow, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        steps > 0 ? '$steps' : 'Active',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? FormaColors.goldenYellow
                              : const Color(0xFF7A5400),
                        ),
                      ),
                      Text(
                        'Steps',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Body (Spend vs Consumed)
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF261D33)
                        : const Color(0xFFF3EEFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: Color(0xFFB085F5), size: 22),
                      const SizedBox(height: 6),
                      Text(
                        burned > 0 ? '$burned' : '0',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFCEB2F7)
                              : const Color(0xFF5B3099),
                        ),
                      ),
                      Text(
                        'Burned',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Heart / Balance
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF331C22)
                        : const Color(0xFFFFEEF0),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        summary.heartRateBpm != null
                            ? Icons.favorite_rounded
                            : Icons.restaurant_rounded,
                        color: FormaColors.coralPink,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary.heartRateBpm != null
                            ? '${summary.heartRateBpm!.toInt()} bpm'
                            : (consumed > 0 ? '$consumed' : 'Fuel'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: FormaColors.coralPink,
                        ),
                      ),
                      Text(
                        summary.heartRateBpm != null ? 'Heart' : 'Consumed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
          ),

          const SizedBox(height: 14),

          // Daily Spend vs Consumed Balance Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: FormaColors.concreteGrey.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.compare_arrows_rounded,
                        size: 16, color: FormaColors.primaryAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Balance: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                    Text(
                      '${netCalories >= 0 ? '+' : ''}$netCalories kcal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: netCalories >= 0
                            ? FormaColors.success
                            : FormaColors.coralPink,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Burn $burned / Eat $consumed',
                  style: TextStyle(
                    fontSize: 11,
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

/// Paints Apple Watch-style concentric circular progress arcs.
class _ConcentricRingsPainter extends CustomPainter {
  final double outerFraction;
  final double middleFraction;
  final double innerFraction;
  final bool isDark;

  _ConcentricRingsPainter({
    required this.outerFraction,
    required this.middleFraction,
    required this.innerFraction,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Outer Ring (Steps - Azure / Icy Blue)
    final rOuter = size.width * 0.46;
    trackPaint
      ..color = const Color(0xFF6BA4E8).withValues(alpha: isDark ? 0.2 : 0.15)
      ..strokeWidth = 9.0;
    canvas.drawCircle(center, rOuter, trackPaint);

    ringPaint
      ..color = const Color(0xFF6BA4E8)
      ..strokeWidth = 9.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rOuter),
      -math.pi / 2,
      2 * math.pi * outerFraction,
      false,
      ringPaint,
    );

    // 2. Middle Ring (Calories Burned - Golden Yellow)
    final rMiddle = size.width * 0.38;
    trackPaint
      ..color = FormaColors.goldenYellow.withValues(alpha: isDark ? 0.2 : 0.15)
      ..strokeWidth = 8.0;
    canvas.drawCircle(center, rMiddle, trackPaint);

    ringPaint
      ..color = FormaColors.goldenYellow
      ..strokeWidth = 8.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rMiddle),
      -math.pi / 2,
      2 * math.pi * middleFraction,
      false,
      ringPaint,
    );

    // 3. Inner Ring (Energy Consistency - Coral)
    final rInner = size.width * 0.30;
    trackPaint
      ..color = FormaColors.coralPink.withValues(alpha: isDark ? 0.2 : 0.15)
      ..strokeWidth = 7.0;
    canvas.drawCircle(center, rInner, trackPaint);

    ringPaint
      ..color = FormaColors.coralPink
      ..strokeWidth = 7.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rInner),
      -math.pi / 2,
      2 * math.pi * innerFraction,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingsPainter oldDelegate) {
    return oldDelegate.outerFraction != outerFraction ||
        oldDelegate.middleFraction != middleFraction ||
        oldDelegate.innerFraction != innerFraction;
  }
}
