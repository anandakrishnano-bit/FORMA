import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/theme/app_colors.dart';

/// FORMA Design System — Typography built on Manrope (Google Fonts).
///
/// Provides editorial-style headings and readable body text in both
/// light and dark colour variants.
class FormaTypography {
  const FormaTypography._();

  // ═══════════════════ Base Font Family ══════════════════════
  static String get _fontFamily => GoogleFonts.manrope().fontFamily!;

  // ═══════════════════ Light-mode Styles ═════════════════════

  static TextStyle get display => _base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
        color: FormaColors.light.primaryText,
      );

  static TextStyle get h1 => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: FormaColors.light.primaryText,
      );

  static TextStyle get h2 => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: FormaColors.light.primaryText,
      );

  static TextStyle get h3 => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: FormaColors.light.primaryText,
      );

  static TextStyle get h4 => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: FormaColors.light.primaryText,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: FormaColors.light.primaryText,
      );

  static TextStyle get bodyMedium => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: FormaColors.light.primaryText,
      );

  static TextStyle get bodySemiBold => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: FormaColors.light.primaryText,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: FormaColors.light.secondaryText,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
        color: FormaColors.light.secondaryText,
      );

  static TextStyle get label => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.5,
        color: FormaColors.light.secondaryText,
      );

  // ═══════════════════ Dark-mode Styles ═════════════════════

  static TextStyle get displayDark => display.copyWith(
        color: FormaColors.dark.primaryText,
      );

  static TextStyle get h1Dark => h1.copyWith(
        color: FormaColors.dark.primaryText,
      );

  static TextStyle get h2Dark => h2.copyWith(
        color: FormaColors.dark.primaryText,
      );

  static TextStyle get h3Dark => h3.copyWith(
        color: FormaColors.dark.primaryText,
      );

  static TextStyle get h4Dark => h4.copyWith(
        color: FormaColors.dark.primaryText,
      );

  static TextStyle get bodyDark => body.copyWith(
        color: FormaColors.dark.primaryText,
      );

  static TextStyle get bodyMediumDark => bodyMedium.copyWith(
        color: FormaColors.dark.primaryText,
      );

  static TextStyle get bodySemiBoldDark => bodySemiBold.copyWith(
        color: FormaColors.dark.primaryText,
      );

  static TextStyle get bodySmallDark => bodySmall.copyWith(
        color: FormaColors.dark.secondaryText,
      );

  static TextStyle get captionDark => caption.copyWith(
        color: FormaColors.dark.secondaryText,
      );

  static TextStyle get labelDark => label.copyWith(
        color: FormaColors.dark.secondaryText,
      );

  // ═══════════ Material TextTheme Builders ══════════════════

  /// Returns a complete [TextTheme] for light mode.
  static TextTheme get lightTextTheme => TextTheme(
        displayLarge: display,
        displayMedium: h1,
        displaySmall: h2,
        headlineMedium: h3,
        headlineSmall: h4,
        titleLarge: h4,
        titleMedium: bodySemiBold,
        titleSmall: bodyMedium.copyWith(fontSize: 14),
        bodyLarge: body,
        bodyMedium: bodySmall,
        bodySmall: caption,
        labelLarge: bodySemiBold.copyWith(fontSize: 14),
        labelMedium: label.copyWith(fontSize: 12),
        labelSmall: label,
      );

  /// Returns a complete [TextTheme] for dark mode.
  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: displayDark,
        displayMedium: h1Dark,
        displaySmall: h2Dark,
        headlineMedium: h3Dark,
        headlineSmall: h4Dark,
        titleLarge: h4Dark,
        titleMedium: bodySemiBoldDark,
        titleSmall: bodyMediumDark.copyWith(fontSize: 14),
        bodyLarge: bodyDark,
        bodyMedium: bodySmallDark,
        bodySmall: captionDark,
        labelLarge: bodySemiBoldDark.copyWith(fontSize: 14),
        labelMedium: labelDark.copyWith(fontSize: 12),
        labelSmall: labelDark,
      );

  // ═══════════════════ Private Helpers ═══════════════════════

  static TextStyle get _base => TextStyle(
        fontFamily: _fontFamily,
        decoration: TextDecoration.none,
      );
}
