import 'package:flutter/material.dart';

/// FORMA Design System — Spacing & radius constants.
///
/// Provides a consistent 4-point spacing scale and border radius tokens.
class FormaSpacing {
  const FormaSpacing._();

  // ─────────────────────── Spacing Scale ────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ─────────────────── Convenience EdgeInsets ────────────────
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingVerticalSm =
      EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd =
      EdgeInsets.symmetric(vertical: md);

  /// Standard screen-edge padding used across screens.
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

/// FORMA Design System — Border Radius tokens.
class FormaRadius {
  const FormaRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double pill = 100.0;

  // ────────────── Convenience BorderRadius ──────────────────
  static final BorderRadius borderRadiusSm = BorderRadius.circular(sm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(md);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(lg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(xl);
  static final BorderRadius borderRadiusXxl = BorderRadius.circular(xxl);
  static final BorderRadius borderRadiusPill = BorderRadius.circular(pill);
}
