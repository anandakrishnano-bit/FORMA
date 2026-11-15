import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/theme/app_colors.dart';

/// The official, centrally maintained FORMA brand logo component.
///
/// Features:
/// - Exact official generated symbol (charcoal upper, icy blue-grey middle,
///   warm golden-orange curved lower, dark circular central detail, golden sparkle).
/// - Transparent asset rendering with smooth anti-aliased edges.
/// - Configurable sizing for splash, app bar, navigation, cards, and avatars.
/// - Optional FORMA wordmark combination.
class FormaLogo extends StatelessWidget {
  /// Diameter or width of the logo symbol.
  final double size;

  /// Whether to display the "FORMA" wordmark alongside the symbol.
  final bool showWordmark;

  /// Font size for the wordmark text when [showWordmark] is true.
  final double wordmarkSize;

  /// Explicit color for the wordmark text (defaults to theme primary text).
  final Color? wordmarkColor;

  /// Gap between the symbol and the wordmark text.
  final double spacing;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Whether to use the tightly cropped asset variant (recommended for UI).
  final bool isCropped;

  const FormaLogo({
    super.key,
    this.size = 40,
    this.showWordmark = false,
    this.wordmarkSize = 20,
    this.wordmarkColor,
    this.spacing = 10,
    this.onTap,
    this.isCropped = true,
  });

  /// Master splash logo variant.
  const FormaLogo.splash({
    super.key,
    this.size = 110,
    this.showWordmark = true,
    this.wordmarkSize = 28,
    this.wordmarkColor,
    this.spacing = 16,
    this.onTap,
    this.isCropped = false,
  });

  /// Compact header or app bar badge.
  const FormaLogo.compact({
    super.key,
    this.size = 32,
    this.showWordmark = false,
    this.wordmarkSize = 16,
    this.wordmarkColor,
    this.spacing = 8,
    this.onTap,
    this.isCropped = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = wordmarkColor ??
        (isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText);

    final assetPath = isCropped
        ? 'assets/images/forma_logo_cropped.png'
        : 'assets/images/forma_logo.png';

    Widget symbol = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (onTap != null) {
      symbol = GestureDetector(onTap: onTap, child: symbol);
    }

    if (!showWordmark) {
      return symbol;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        symbol,
        SizedBox(width: spacing),
        Text(
          'FORMA',
          style: GoogleFonts.plusJakartaSans(
            fontSize: wordmarkSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
