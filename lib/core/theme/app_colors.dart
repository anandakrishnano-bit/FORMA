import 'package:flutter/material.dart';

/// FORMA Design System — Color palette for light and dark modes.
///
/// Usage:
/// ```dart
/// final bg = FormaColors.light.primaryBg;
/// final darkBg = FormaColors.dark.primaryBg;
/// ```
class FormaColors {
  const FormaColors._();

  // ─────────────────────── Light Mode ───────────────────────
  static const FormaColorScheme light = FormaColorScheme(
    primaryBg: Color(0xFFF5F1E9), // Warm Cream primary background
    secondaryBg: Color(0xFFEFECE4),
    primaryText: Color(0xFF171719), // Charcoal primary typography
    secondaryText: Color(0xFF77736C),
    primaryAccent: Color(0xFFFFC443), // Golden Yellow targeted accent
    secondaryAccent: Color(0xFFC5D0DE), // Icy Blue prominent secondary accent
    success: Color(0xFF88A95C),
    cardBg: Color(0xFFFFFFFF),
    error: Color(0xFFF27689), // Coral Pink
    divider: Color(0xFFE5E2DA),
    shadow: Color(0x1A000000),
    overlay: Color(0x33000000),
  );

  // ─────────────────────── Dark Mode ────────────────────────
  static const FormaColorScheme dark = FormaColorScheme(
    primaryBg: Color(0xFF171719), // Deep Charcoal structure
    secondaryBg: Color(0xFF1F1F23),
    primaryText: Color(0xFFF5F1E9),
    secondaryText: Color(0xFFA6A29A),
    primaryAccent: Color(0xFFFFC443),
    secondaryAccent: Color(0xFFC5D0DE), // Icy Blue
    success: Color(0xFF88A95C),
    cardBg: Color(0xFF222227),
    error: Color(0xFFF27689),
    divider: Color(0xFF333339),
    shadow: Color(0x40000000),
    overlay: Color(0x66000000),
  );

  // ─────────────────────── Extended Palette ─────────────────
  static const Color icyBlue = Color(0xFFC5D0DE);
  static const Color coralPink = Color(0xFFF27689);
  static const Color charcoal = Color(0xFF171719);
  static const Color warmCream = Color(0xFFF5F1E9);
  static const Color goldenYellow = Color(0xFFFFC443);
  static const Color concreteGrey = Color(0xFFB8B7B5);

  // ──────────────── Bento Pastel Palette (Inspire UI) ────────
  static const Color terracotta = Color(0xFFFF7A59);
  static const Color terracottaPastel = Color(0xFFFFEFEA);
  static const Color terracottaDark = Color(0xFF2E1E1A);

  static const Color sage = Color(0xFF7AA868);
  static const Color sagePastel = Color(0xFFEFF6EC);
  static const Color sageDark = Color(0xFF1E2B1B);

  static const Color lavender = Color(0xFF8B80F9);
  static const Color lavenderPastel = Color(0xFFF2F0FE);
  static const Color lavenderDark = Color(0xFF23213A);

  static const Color amber = Color(0xFFFFAA2C);
  static const Color amberPastel = Color(0xFFFFF6E8);
  static const Color amberDark = Color(0xFF2E2417);

  static const Color azure = Color(0xFF54A0FF);
  static const Color azurePastel = Color(0xFFEEF5FF);
  static const Color azureDark = Color(0xFF172332);

  static const Color obsidian = Color(0xFF141416);

  // ─────────────── Static Direct Aliases ─────────────────────
  static const Color primaryAccent = goldenYellow;
  static const Color secondaryAccent = icyBlue;
  static const Color success = Color(0xFF88A95C);
  static const Color error = coralPink;
  static const Color divider = Color(0xFFE5E2DA);

  // Background aliases
  static const Color darkBackground = charcoal;
  static const Color lightBackground = warmCream;
  static const Color darkSecondaryBackground = Color(0xFF1F1F23);
  static const Color lightSecondaryBackground = Color(0xFFEFECE4);
  static const Color darkCardBackground = Color(0xFF222227);
  static const Color lightCardBackground = Color(0xFFFFFFFF);

  // Text aliases
  static const Color darkPrimaryText = warmCream;
  static const Color lightPrimaryText = charcoal;
  static const Color darkSecondaryText = Color(0xFFA6A29A);
  static const Color lightSecondaryText = Color(0xFF77736C);

  // ─────────────── Semantic / Functional ────────────────────
  static const Color warning = Color(0xFFFFAA2C);
  static const Color info = icyBlue;

  // ─────────────── Unified Global Semantic Tokens ───────────
  // Screen and feature semantic balance
  static const Color semanticSteps = Color(0xFF9CAF88); // Sage Green
  static const Color semanticHydration = Color(0xFF7FA1C3); // Icy Blue Accent
  static const Color semanticWorkout = coralPink; // Coral Pink
  static const Color semanticNutrition = goldenYellow; // Subtle Golden Yellow
  static const Color semanticHabits = icyBlue; // Icy Blue
  static const Color semanticExpenses =
      charcoal; // Obsidian Charcoal with Warm Cream
  static const Color semanticGeneral = concreteGrey; // Concrete Grey
  static const Color semanticWarning = Color(0xFFFFAA2C); // Amber Warning
  static const Color semanticError = coralPink; // Coral Alert Red
  static const Color semanticSuccess =
      Color(0xFF88A95C); // Pure Confirmation Green

  /// Returns the appropriate color scheme for the given [brightness].
  static FormaColorScheme of(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

/// Immutable color scheme token set used by both light and dark modes.
class FormaColorScheme {
  final Color primaryBg;
  final Color secondaryBg;
  final Color primaryText;
  final Color secondaryText;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color success;
  final Color cardBg;
  final Color error;
  final Color divider;
  final Color shadow;
  final Color overlay;

  const FormaColorScheme({
    required this.primaryBg,
    required this.secondaryBg,
    required this.primaryText,
    required this.secondaryText,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.success,
    required this.cardBg,
    required this.error,
    required this.divider,
    required this.shadow,
    required this.overlay,
  });
}
