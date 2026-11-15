import 'package:flutter/animation.dart';

/// Standard curated animation easings based on https://easings.net
/// and Flutter's Curves specifications (https://api.flutter.dev/flutter/animation/Curves-class.html).
///
/// Use these throughout FORMA for fluid, tactile, natural physics-based motion.
class FormaEasings {
  FormaEasings._();

  // ─── EASE OUT (Decelerating entrances, user interactions, card pops) ───

  /// easeOutCubic: Smooth deceleration. Ideal for general card expansions,
  /// sheet presentations, and list entry animations.
  /// https://easings.net/#easeOutCubic
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// easeOutQuart: Slightly faster initial burst and longer deceleration.
  /// https://easings.net/#easeOutQuart
  static const Curve easeOutQuart = Curves.easeOutQuart;

  /// easeOutQuint: High-inertia fluid easing. Used for prominent full-screen transitions.
  /// https://easings.net/#easeOutQuint
  static const Curve easeOutQuint = Curves.easeOutQuint;

  /// easeOutExpo: Ultra-smooth abrupt stop. Excellent for snappy bar graphs and progress fills.
  /// https://easings.net/#easeOutExpo
  static const Curve easeOutExpo = Curves.easeOutExpo;

  /// easeOutBack: Gentle spring overshoot and settle.
  /// Perfect for habit checkoffs, button releases, and toggle switches.
  /// https://easings.net/#easeOutBack
  static const Curve easeOutBack = Curves.easeOutBack;

  // ─── EASE IN-OUT (Symmetrical state changes, theme transitions, page tabs) ───

  /// easeInOutCubic: Symmetrical acceleration and deceleration.
  /// Ideal for tab switches and day calendar sliding.
  /// https://easings.net/#easeInOutCubic
  static const Curve easeInOutCubic = Curves.easeInOutCubic;

  /// easeInOutQuart: Deeper in-out curve for long morphing containers.
  /// https://easings.net/#easeInOutQuart
  static const Curve easeInOutQuart = Curves.easeInOutQuart;

  /// easeInOutExpo: Dramatic easing for major state shifts.
  /// https://easings.net/#easeInOutExpo
  static const Curve easeInOutExpo = Curves.easeInOutExpo;

  /// fastOutSlowIn: Flutter standard Material motion.
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  // ─── Standard Interaction Durations ───
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration medium = Duration(milliseconds: 360);
  static const Duration slow = Duration(milliseconds: 500);
}
