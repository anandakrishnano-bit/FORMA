import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:forma/core/theme/app_colors.dart';

/// A segment in a [FormaProgressRing] used for multi‑segment displays
/// (e.g. macros breakdown).
class ProgressSegment {
  const ProgressSegment({
    required this.value,
    required this.color,
  });

  /// Fractional value (0 – 1) for this segment.
  final double value;

  /// Colour of this segment arc.
  final Color color;
}

/// A circular progress indicator following the FORMA design system.
///
/// Can show a single progress value or multiple [segments] (for macro
/// breakdowns). Animates smoothly on value changes. Accepts a [child] widget
/// rendered in the centre.
class FormaProgressRing extends StatefulWidget {
  const FormaProgressRing({
    super.key,
    this.progress = 0,
    this.segments,
    this.size = 120,
    this.strokeWidth = 10,
    this.color,
    this.backgroundColor,
    this.child,
    this.animationDuration = const Duration(milliseconds: 600),
  }) : assert(segments == null || progress == 0,
            'Use either progress or segments, not both');

  /// Single progress value (0 – 1). Ignored when [segments] is provided.
  final double progress;

  /// Multiple coloured segments whose values should sum to ≤ 1.
  final List<ProgressSegment>? segments;

  /// Outer diameter of the ring.
  final double size;

  /// Stroke width of the ring arcs.
  final double strokeWidth;

  /// Colour for single‑progress mode.
  final Color? color;

  /// Background track colour.
  final Color? backgroundColor;

  /// Widget displayed in the centre of the ring.
  final Widget? child;

  /// Duration of the value‑change animation.
  final Duration animationDuration;

  @override
  State<FormaProgressRing> createState() => _FormaProgressRingState();
}

class _FormaProgressRingState extends State<FormaProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(begin: 0, end: _effectiveProgress)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  double get _effectiveProgress {
    if (widget.segments != null) {
      return widget.segments!
          .fold<double>(0, (s, seg) => s + seg.value)
          .clamp(0, 1);
    }
    return widget.progress.clamp(0, 1);
  }

  @override
  void didUpdateWidget(FormaProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgress = _effectiveProgress;
    if ((_animation as Tween<double>?) != null || _oldProgress != newProgress) {
      _oldProgress = _animation.value;
      _animation = Tween<double>(begin: _oldProgress, end: newProgress).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FormaColors.of(Theme.of(context).brightness);
    final bgColor =
        widget.backgroundColor ?? colors.divider.withValues(alpha: 0.3);
    final fgColor = widget.color ?? colors.primaryAccent;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: _animation.value,
              segments: widget.segments,
              strokeWidth: widget.strokeWidth,
              backgroundColor: bgColor,
              foregroundColor: fgColor,
            ),
            child: child,
          );
        },
        child: widget.child != null ? Center(child: widget.child) : null,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.segments,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final double progress;
  final List<ProgressSegment>? segments;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    // Background track.
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (segments != null && segments!.isNotEmpty) {
      // Multi‑segment mode.
      double currentAngle = startAngle;
      final totalProgress = progress; // animated total
      final segmentTotal = segments!
          .fold<double>(0, (s, seg) => s + seg.value)
          .clamp(0.0001, 1.0);

      for (final seg in segments!) {
        final fraction = seg.value / segmentTotal;
        final sweep = 2 * math.pi * totalProgress * fraction;
        if (sweep <= 0) continue;

        final paint = Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          currentAngle,
          sweep,
          false,
          paint,
        );
        currentAngle += sweep;
      }
    } else {
      // Single progress mode.
      if (progress <= 0) return;
      final sweep = 2 * math.pi * progress;
      final fgPaint = Paint()
        ..color = foregroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      segments != oldDelegate.segments ||
      strokeWidth != oldDelegate.strokeWidth ||
      backgroundColor != oldDelegate.backgroundColor ||
      foregroundColor != oldDelegate.foregroundColor;
}
