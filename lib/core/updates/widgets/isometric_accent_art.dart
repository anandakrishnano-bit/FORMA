import 'package:flutter/material.dart';

/// Custom-painted 3D isometric geometric sculpture accentuating the update UI,
/// matching the purple isometric architectural illustration from the reference design.
class IsometricAccentArt extends StatelessWidget {
  final double size;
  final Color primaryColor;

  const IsometricAccentArt({
    super.key,
    this.size = 200,
    this.primaryColor = const Color(0xFF8A3FFC),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IsometricSculpturePainter(primaryColor: primaryColor),
      ),
    );
  }
}

class _IsometricSculpturePainter extends CustomPainter {
  final Color primaryColor;

  _IsometricSculpturePainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final lightTop = primaryColor.withValues(alpha: 0.95);
    final mediumLeft = Color.lerp(primaryColor, Colors.black, 0.25)!;
    final darkRight = Color.lerp(primaryColor, Colors.black, 0.45)!;
    final strokeColor = primaryColor.withValues(alpha: 0.4);

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Helper to draw an isometric prism block
    void drawIsoBlock({
      required Offset origin,
      required double dx,
      required double dy,
      required double dz,
      Color? topColor,
      Color? leftColor,
      Color? rightColor,
    }) {
      // 30-degree isometric projection constants
      const cos30 = 0.866025;
      const sin30 = 0.5;

      Offset project(double x, double y, double z) {
        final px = origin.dx + (x - y) * cos30;
        final py = origin.dy + (x + y) * sin30 - z;
        return Offset(px, py);
      }

      // 8 vertices of cuboid (p000 occluded from isometric angle)
      final p100 = project(dx, 0, 0);
      final p110 = project(dx, dy, 0);
      final p010 = project(0, dy, 0);

      final p001 = project(0, 0, dz);
      final p101 = project(dx, 0, dz);
      final p111 = project(dx, dy, dz);
      final p011 = project(0, dy, dz);

      // Top Face
      final topPath = Path()
        ..moveTo(p001.dx, p001.dy)
        ..lineTo(p101.dx, p101.dy)
        ..lineTo(p111.dx, p111.dy)
        ..lineTo(p011.dx, p011.dy)
        ..close();
      canvas.drawPath(
        topPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              topColor ?? lightTop,
              Color.lerp(topColor ?? lightTop, Colors.white, 0.15)!,
            ],
          ).createShader(topPath.getBounds()),
      );
      canvas.drawPath(topPath, linePaint);

      // Left Face
      final leftPath = Path()
        ..moveTo(p010.dx, p010.dy)
        ..lineTo(p110.dx, p110.dy)
        ..lineTo(p111.dx, p111.dy)
        ..lineTo(p011.dx, p011.dy)
        ..close();
      canvas.drawPath(
        leftPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              leftColor ?? mediumLeft,
              Color.lerp(leftColor ?? mediumLeft, Colors.black, 0.3)!,
            ],
          ).createShader(leftPath.getBounds()),
      );
      canvas.drawPath(leftPath, linePaint);

      // Right Face
      final rightPath = Path()
        ..moveTo(p100.dx, p100.dy)
        ..lineTo(p110.dx, p110.dy)
        ..lineTo(p111.dx, p111.dy)
        ..lineTo(p101.dx, p101.dy)
        ..close();
      canvas.drawPath(
        rightPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              rightColor ?? darkRight,
              Color.lerp(rightColor ?? darkRight, Colors.black, 0.4)!,
            ],
          ).createShader(rightPath.getBounds()),
      );
      canvas.drawPath(rightPath, linePaint);
    }

    // Interlocking architectural pillars matching reference sculpture
    final center = Offset(w * 0.48, h * 0.62);

    // Ambient radial glow behind the sculpture
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.45));
    canvas.drawCircle(center, w * 0.45, glowPaint);

    // Pillar 1: Back tall pillar
    drawIsoBlock(
      origin: Offset(center.dx - w * 0.12, center.dy + h * 0.05),
      dx: w * 0.16,
      dy: w * 0.16,
      dz: h * 0.50,
    );

    // Pillar 2: Front medium offset pillar
    drawIsoBlock(
      origin: Offset(center.dx + w * 0.08, center.dy + h * 0.12),
      dx: w * 0.18,
      dy: w * 0.18,
      dz: h * 0.32,
    );

    // Pillar 3: Left connecting bridge block
    drawIsoBlock(
      origin: Offset(center.dx - w * 0.22, center.dy + h * 0.20),
      dx: w * 0.16,
      dy: w * 0.24,
      dz: h * 0.18,
    );

    // Pillar 4: Front right low pedestal
    drawIsoBlock(
      origin: Offset(center.dx + w * 0.16, center.dy + h * 0.28),
      dx: w * 0.14,
      dy: w * 0.14,
      dz: h * 0.12,
    );
  }

  @override
  bool shouldRepaint(covariant _IsometricSculpturePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor;
  }
}
