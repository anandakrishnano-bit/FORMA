import 'package:flutter/material.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';
import 'package:forma/core/theme/app_typography.dart';

/// Visual variant for [FormaButton].
enum FormaButtonVariant { primary, secondary, text, danger }

/// Size preset for [FormaButton].
enum FormaButtonSize { small, medium, large }

/// A premium FORMA design‑system button.
///
/// Supports [FormaButtonVariant]s (primary filled, secondary outlined, text,
/// danger), three [FormaButtonSize]s, loading/disabled states, optional leading
/// icon, and full‑width mode.
class FormaButton extends StatelessWidget {
  const FormaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = FormaButtonVariant.primary,
    this.size = FormaButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  /// Button label text.
  final String label;

  /// Tap callback. When `null` or [isLoading] is `true` the button appears
  /// disabled.
  final VoidCallback? onPressed;

  /// Visual variant.
  final FormaButtonVariant variant;

  /// Size preset.
  final FormaButtonSize size;

  /// When `true` an indeterminate spinner replaces the label and the button is
  /// disabled.
  final bool isLoading;

  /// Expand to fill the available width.
  final bool isFullWidth;

  /// Optional leading icon shown before the label.
  final IconData? icon;

  // ──────────────────── Helpers ────────────────────────

  double get _height {
    switch (size) {
      case FormaButtonSize.small:
        return 40;
      case FormaButtonSize.medium:
        return 52;
      case FormaButtonSize.large:
        return 56;
    }
  }

  double get _fontSize {
    switch (size) {
      case FormaButtonSize.small:
        return 13;
      case FormaButtonSize.medium:
        return 15;
      case FormaButtonSize.large:
        return 16;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case FormaButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 10);
      case FormaButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 14);
      case FormaButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20);
    }
  }

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = FormaColors.of(Theme.of(context).brightness);

    final Color bgColor;
    final Color fgColor;
    final Color? borderColor;

    switch (variant) {
      case FormaButtonVariant.primary:
        bgColor = _enabled
            ? colors.primaryAccent
            : colors.primaryAccent.withValues(alpha: 0.4);
        fgColor = FormaColors.charcoal;
        borderColor = null;
        break;
      case FormaButtonVariant.secondary:
        // Solid high-contrast surface so buttons never blend into background cards
        bgColor = isDark ? FormaColors.charcoal : Colors.white;
        fgColor = isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal;
        borderColor = isDark
            ? Colors.white.withValues(alpha: 0.18)
            : FormaColors.charcoal.withValues(alpha: 0.14);
        break;
      case FormaButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = _enabled
            ? colors.primaryAccent
            : colors.primaryAccent.withValues(alpha: 0.4);
        borderColor = null;
        break;
      case FormaButtonVariant.danger:
        bgColor = _enabled ? colors.error : colors.error.withValues(alpha: 0.4);
        fgColor = Colors.white;
        borderColor = null;
        break;
    }

    final textStyle = TextStyle(
      fontFamily: FormaTypography.body.fontFamily,
      fontSize: _fontSize,
      fontWeight: FontWeight.w700,
      color: fgColor,
    );

    final Widget child;
    if (isLoading) {
      child = SizedBox(
        width: _fontSize + 4,
        height: _fontSize + 4,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    } else {
      final labelWidget = Text(
        label,
        style: textStyle,
        maxLines: 1,
      );
      if (icon != null) {
        child = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: _fontSize + 4, color: fgColor),
            const SizedBox(width: 6),
            labelWidget,
          ],
        );
      } else {
        child = Center(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: labelWidget,
        );
      }
    }

    final button = Material(
      color: bgColor,
      borderRadius: FormaRadius.borderRadiusXl,
      elevation: (variant == FormaButtonVariant.primary ||
              variant == FormaButtonVariant.secondary)
          ? 1.0
          : 0.0,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
      child: InkWell(
        onTap: _enabled ? onPressed : null,
        borderRadius: FormaRadius.borderRadiusXl,
        splashColor: fgColor.withValues(alpha: 0.08),
        highlightColor: fgColor.withValues(alpha: 0.04),
        child: Container(
          height: _height,
          padding: _padding,
          decoration: borderColor != null
              ? BoxDecoration(
                  borderRadius: FormaRadius.borderRadiusXl,
                  border: Border.all(color: borderColor, width: 1.5),
                )
              : null,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: child,
          ),
        ),
      ),
    );

    final interactiveButton = _enabled
        ? FormaBounceable(
            onTap: onPressed,
            child: button,
          )
        : button;

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: interactiveButton);
    }
    return interactiveButton;
  }
}
