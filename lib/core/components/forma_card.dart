import 'package:flutter/material.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';
import 'package:forma/core/theme/app_typography.dart';

/// A rounded premium card following the FORMA design system.
///
/// Supports an optional [title], [subtitle], [trailing] widget, [onTap]
/// handler, and custom [child] content.
class FormaCard extends StatelessWidget {
  const FormaCard({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.border,
    this.margin,
  });

  /// Optional title text displayed at the top.
  final String? title;

  /// Optional subtitle displayed below the title.
  final String? subtitle;

  /// Widget shown at the trailing edge of the header row.
  final Widget? trailing;

  /// Main body content placed below the header.
  final Widget? child;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Inner padding. Defaults to `FormaSpacing.paddingMd`.
  final EdgeInsets? padding;

  /// Background colour override.
  final Color? backgroundColor;

  /// Card elevation. Defaults to 0 (shadow provided via [BoxDecoration]).
  final double? elevation;

  /// Optional border.
  final Border? border;

  /// Outer margin.
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final colors = FormaColors.of(Theme.of(context).brightness);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectivePadding = padding ?? FormaSpacing.paddingMd;
    final effectiveBg = backgroundColor ?? colors.cardBg;

    final bool hasHeader =
        title != null || subtitle != null || trailing != null;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: FormaRadius.borderRadiusXl,
        border: border != null
            ? border
            : Border.all(
                color: colors.divider.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: FormaRadius.borderRadiusXl,
        child: InkWell(
          onTap: onTap,
          borderRadius: FormaRadius.borderRadiusXl,
          splashColor: colors.primaryAccent.withValues(alpha: 0.06),
          highlightColor: colors.primaryAccent.withValues(alpha: 0.03),
          child: Padding(
            padding: effectivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasHeader) _buildHeader(colors, isDark),
                if (hasHeader && child != null)
                  const SizedBox(height: FormaSpacing.sm),
                if (child != null) child!,
              ],
            ),
          ),
        ),
      ),
    );

    return onTap != null
        ? FormaBounceable(
            onTap: onTap,
            child: card,
          )
        : card;
  }

  Widget _buildHeader(FormaColorScheme colors, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: (isDark
                      ? FormaTypography.bodySemiBoldDark
                      : FormaTypography.bodySemiBold),
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: (isDark
                      ? FormaTypography.captionDark
                      : FormaTypography.caption),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
