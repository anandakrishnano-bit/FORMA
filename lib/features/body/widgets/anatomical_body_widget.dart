import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/models/muscle_tracker_model.dart';

/// Clean, editorial anatomical body illustration widget.
///
/// Features:
/// - Front & Back anatomical body views
/// - Accurate major muscle group regions
/// - Real-time highlight for trained muscles in logged workouts
/// - Interactive muscle group selection
class AnatomicalBodyWidget extends StatefulWidget {
  final Set<String> trainedMuscles;
  final Set<String> plannedMuscles;
  final ValueChanged<MajorMuscleGroup>? onMuscleSelected;
  final MajorMuscleGroup? selectedMuscle;

  const AnatomicalBodyWidget({
    super.key,
    this.trainedMuscles = const {},
    this.plannedMuscles = const {},
    this.onMuscleSelected,
    this.selectedMuscle,
  });

  @override
  State<AnatomicalBodyWidget> createState() => _AnatomicalBodyWidgetState();
}

class _AnatomicalBodyWidgetState extends State<AnatomicalBodyWidget> {
  bool _showFrontView = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? FormaColors.charcoal : Colors.white;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;

    final visibleMuscles = MajorMuscleGroup.all.where((m) {
      return _showFrontView ? m.isFront : m.isBack;
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // View Toggle: Front View vs Back View
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showFrontView ? 'Anterior (Front)' : 'Posterior (Back)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : const Color(0xFFF0EDE5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildToggleOption('Front', _showFrontView, () {
                      setState(() => _showFrontView = true);
                    }, isDark),
                    _buildToggleOption('Back', !_showFrontView, () {
                      setState(() => _showFrontView = false);
                    }, isDark),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Anatomical Body Visual Display
          SizedBox(
            height: 290,
            child: Row(
              children: [
                // Visual Canvas representation
                Expanded(
                  flex: 5,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(180, 280),
                      painter: _AnatomicalSilhouettePainter(
                        isFront: _showFrontView,
                        trainedMuscles: widget.trainedMuscles,
                        selectedMuscleId: widget.selectedMuscle?.id,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),

                // Interactive Muscle Group Chips
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: visibleMuscles.map((muscle) {
                        final isTrained = widget.trainedMuscles.any(
                          (m) =>
                              m.toLowerCase() == muscle.name.toLowerCase() ||
                              m.toLowerCase() == muscle.id,
                        );
                        final isPlanned = widget.plannedMuscles.any(
                          (m) =>
                              m.toLowerCase() == muscle.name.toLowerCase() ||
                              m.toLowerCase() == muscle.id,
                        );
                        final isSelected =
                            widget.selectedMuscle?.id == muscle.id;

                        Color statusColor = secondaryTextColor;
                        String statusLabel = 'Untrained';
                        if (isTrained) {
                          statusColor = FormaColors.success;
                          statusLabel = 'Trained';
                        } else if (isPlanned) {
                          statusColor = FormaColors.goldenYellow;
                          statusLabel = 'Planned';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: FormaBounceable(
                            onTap: () {
                              widget.onMuscleSelected?.call(muscle);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? muscle.color
                                        .withValues(alpha: isDark ? 0.3 : 0.18)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : const Color(0xFFF7F5EE)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? muscle.color
                                      : (isTrained
                                          ? FormaColors.success
                                              .withValues(alpha: 0.5)
                                          : Colors.transparent),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isTrained
                                          ? FormaColors.success
                                          : (isPlanned
                                              ? FormaColors.goldenYellow
                                              : Colors.grey
                                                  .withValues(alpha: 0.4)),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      muscle.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? primaryTextColor
                                            : (isDark
                                                ? Colors.white70
                                                : FormaColors.charcoal),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(FormaColors.success, 'Trained this week'),
              const SizedBox(width: 16),
              _buildLegendDot(FormaColors.goldenYellow, 'Planned'),
              const SizedBox(width: 16),
              _buildLegendDot(Colors.grey.withValues(alpha: 0.5), 'Untrained'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
      String text, bool active, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? FormaColors.primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active
                ? FormaColors.charcoal
                : (isDark ? Colors.white70 : FormaColors.charcoal),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Vector Anatomical Silhouette Painter with distinct, accurately placed muscle partitions.
class _AnatomicalSilhouettePainter extends CustomPainter {
  final bool isFront;
  final Set<String> trainedMuscles;
  final String? selectedMuscleId;
  final bool isDark;

  _AnatomicalSilhouettePainter({
    required this.isFront,
    required this.trainedMuscles,
    this.selectedMuscleId,
    required this.isDark,
  });

  bool _isTrained(String id) {
    return trainedMuscles.any((m) => m.toLowerCase().contains(id));
  }

  Color _getRegionColor(String id, Color defaultColor) {
    if (selectedMuscleId == id) {
      return FormaColors.goldenYellow;
    }
    if (_isTrained(id)) {
      return FormaColors.success.withValues(alpha: 0.85);
    }
    return defaultColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final w = size.width;
    final h = size.height;

    final basePaint = Paint()
      ..color =
          (isDark ? Colors.white : FormaColors.charcoal).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // 1. Head
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, h * 0.08), width: w * 0.24, height: h * 0.12),
      basePaint,
    );

    // 2. Neck & Traps
    final neckPath = Path()
      ..moveTo(cx - w * 0.09, h * 0.12)
      ..lineTo(cx + w * 0.09, h * 0.12)
      ..lineTo(cx + w * 0.13, h * 0.17)
      ..lineTo(cx - w * 0.13, h * 0.17)
      ..close();
    canvas.drawPath(neckPath, basePaint);

    if (isFront) {
      // ── FRONT VIEW ──

      // Shoulders (Deltoids)
      final shoulderPaint = Paint()
        ..color = _getRegionColor('shoulder',
            isDark ? const Color(0xFF333338) : const Color(0xFFE2DFD6))
        ..style = PaintingStyle.fill;
      // Left shoulder
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - w * 0.29, h * 0.21),
              width: w * 0.16,
              height: h * 0.09),
          shoulderPaint);
      // Right shoulder
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + w * 0.29, h * 0.21),
              width: w * 0.16,
              height: h * 0.09),
          shoulderPaint);

      // Chest (Pectoralis)
      final chestPaint = Paint()
        ..color = _getRegionColor(
            'chest', isDark ? const Color(0xFF383334) : const Color(0xFFE8E0DE))
        ..style = PaintingStyle.fill;
      final chestRect = Rect.fromCenter(
          center: Offset(cx, h * 0.24), width: w * 0.42, height: h * 0.10);
      canvas.drawRRect(
          RRect.fromRectAndRadius(chestRect, const Radius.circular(10)),
          chestPaint);

      // Biceps & Arms
      final bicepPaint = Paint()
        ..color = _getRegionColor(
            'bicep', isDark ? const Color(0xFF2E2C38) : const Color(0xFFE2E0EC))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx - w * 0.35, h * 0.31),
                  width: w * 0.13,
                  height: h * 0.10),
              const Radius.circular(8)),
          bicepPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + w * 0.35, h * 0.31),
                  width: w * 0.13,
                  height: h * 0.10),
              const Radius.circular(8)),
          bicepPaint);

      // Forearms
      final forearmPaint = Paint()
        ..color = _getRegionColor('forearm',
            isDark ? const Color(0xFF28282C) : const Color(0xFFECEAE4))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx - w * 0.41, h * 0.42),
                  width: w * 0.11,
                  height: h * 0.12),
              const Radius.circular(6)),
          forearmPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + w * 0.41, h * 0.42),
                  width: w * 0.11,
                  height: h * 0.12),
              const Radius.circular(6)),
          forearmPaint);

      // Abs & Core
      final absPaint = Paint()
        ..color = _getRegionColor(
            'ab', isDark ? const Color(0xFF33302A) : const Color(0xFFEAE5DC))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx, h * 0.37),
                  width: w * 0.34,
                  height: h * 0.14),
              const Radius.circular(8)),
          absPaint);

      // Quadriceps
      final quadPaint = Paint()
        ..color = _getRegionColor(
            'quad', isDark ? const Color(0xFF283226) : const Color(0xFFDFEADB))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx - w * 0.15, h * 0.58),
                  width: w * 0.20,
                  height: h * 0.21),
              const Radius.circular(14)),
          quadPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + w * 0.15, h * 0.58),
                  width: w * 0.20,
                  height: h * 0.21),
              const Radius.circular(14)),
          quadPaint);

      // Calves
      final calfPaint = Paint()
        ..color = _getRegionColor(
            'calf', isDark ? const Color(0xFF28302A) : const Color(0xFFDEE5E0))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx - w * 0.15, h * 0.81),
                  width: w * 0.16,
                  height: h * 0.18),
              const Radius.circular(10)),
          calfPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + w * 0.15, h * 0.81),
                  width: w * 0.16,
                  height: h * 0.18),
              const Radius.circular(10)),
          calfPaint);
    } else {
      // ── BACK VIEW ──

      // Back (Upper Lats / Rhomboids / Traps)
      final backPaint = Paint()
        ..color = _getRegionColor(
            'back', isDark ? const Color(0xFF222C38) : const Color(0xFFDBE5F2))
        ..style = PaintingStyle.fill;
      final backPath = Path()
        ..moveTo(cx - w * 0.28, h * 0.19)
        ..lineTo(cx + w * 0.28, h * 0.19)
        ..lineTo(cx + w * 0.18, h * 0.39)
        ..lineTo(cx - w * 0.18, h * 0.39)
        ..close();
      canvas.drawPath(backPath, backPaint);

      // Triceps
      final tricepPaint = Paint()
        ..color = _getRegionColor('tricep',
            isDark ? const Color(0xFF302C38) : const Color(0xFFE4E0EC))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx - w * 0.35, h * 0.31),
                  width: w * 0.13,
                  height: h * 0.11),
              const Radius.circular(8)),
          tricepPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + w * 0.35, h * 0.31),
                  width: w * 0.13,
                  height: h * 0.11),
              const Radius.circular(8)),
          tricepPaint);

      // Glutes
      final glutePaint = Paint()
        ..color = _getRegionColor(
            'glute', isDark ? const Color(0xFF382A24) : const Color(0xFFEFE2DC))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx - w * 0.13, h * 0.46),
                  width: w * 0.22,
                  height: h * 0.10),
              const Radius.circular(12)),
          glutePaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + w * 0.13, h * 0.46),
                  width: w * 0.22,
                  height: h * 0.10),
              const Radius.circular(12)),
          glutePaint);

      // Hamstrings
      final hamstringPaint = Paint()
        ..color = _getRegionColor('hamstring',
            isDark ? const Color(0xFF283226) : const Color(0xFFDFEADB))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx - w * 0.15, h * 0.60),
                  width: w * 0.20,
                  height: h * 0.16),
              const Radius.circular(12)),
          hamstringPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + w * 0.15, h * 0.60),
                  width: w * 0.20,
                  height: h * 0.16),
              const Radius.circular(12)),
          hamstringPaint);

      // Calves (Back)
      final calfPaint = Paint()
        ..color = _getRegionColor(
            'calf', isDark ? const Color(0xFF28302A) : const Color(0xFFDEE5E0))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx - w * 0.15, h * 0.81),
                  width: w * 0.16,
                  height: h * 0.18),
              const Radius.circular(10)),
          calfPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + w * 0.15, h * 0.81),
                  width: w * 0.16,
                  height: h * 0.18),
              const Radius.circular(10)),
          calfPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnatomicalSilhouettePainter oldDelegate) {
    return oldDelegate.isFront != isFront ||
        oldDelegate.selectedMuscleId != selectedMuscleId ||
        oldDelegate.trainedMuscles != trainedMuscles ||
        oldDelegate.isDark != isDark;
  }
}
