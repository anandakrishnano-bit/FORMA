import 'package:flutter/material.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';
import 'package:forma/core/theme/app_typography.dart';

/// A rounded text field following the FORMA design system.
///
/// Features filled background, focus‑animated accent border, and full support
/// for label, hint, prefix/suffix icons, error text, obscure text, multiline,
/// and validation.
class FormaTextField extends StatefulWidget {
  const FormaTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<FormaTextField> createState() => _FormaTextFieldState();
}

class _FormaTextFieldState extends State<FormaTextField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _borderAnim;
  late final Animation<double> _borderWidth;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _borderAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _borderWidth = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _borderAnim, curve: Curves.easeInOut),
    );
  }

  void _onFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _borderAnim.forward();
    } else {
      _borderAnim.reverse();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    _borderAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = FormaColors.of(Theme.of(context).brightness);
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;

    final fillColor =
        isDark ? colors.secondaryBg : colors.secondaryBg.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style:
                (isDark ? FormaTypography.captionDark : FormaTypography.caption)
                    .copyWith(
              fontWeight: FontWeight.w600,
              color: hasError ? colors.error : null,
            ),
          ),
          const SizedBox(height: FormaSpacing.sm),
        ],
        AnimatedBuilder(
          animation: _borderAnim,
          builder: (context, child) {
            return TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              minLines: widget.minLines,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              style: isDark ? FormaTypography.bodyDark : FormaTypography.body,
              cursorColor: colors.primaryAccent,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: (isDark
                        ? FormaTypography.bodySmallDark
                        : FormaTypography.bodySmall)
                    .copyWith(
                        color: colors.secondaryText.withValues(alpha: 0.6)),
                filled: true,
                fillColor: fillColor,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon,
                        size: 20,
                        color: _hasFocus
                            ? colors.primaryAccent
                            : colors.secondaryText)
                    : null,
                suffixIcon: widget.suffixIcon,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: FormaSpacing.md,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: FormaRadius.borderRadiusLg,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: FormaRadius.borderRadiusLg,
                  borderSide: hasError
                      ? BorderSide(color: colors.error, width: 1.5)
                      : BorderSide(
                          color: colors.divider.withValues(alpha: 0.5),
                          width: 1,
                        ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: FormaRadius.borderRadiusLg,
                  borderSide: BorderSide(
                    color: hasError ? colors.error : colors.primaryAccent,
                    width: _borderWidth.value,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: FormaRadius.borderRadiusLg,
                  borderSide: BorderSide(
                    color: colors.divider.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: FormaRadius.borderRadiusLg,
                  borderSide: BorderSide(color: colors.error, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: FormaRadius.borderRadiusLg,
                  borderSide: BorderSide(color: colors.error, width: 2),
                ),
              ),
            );
          },
        ),
        if (hasError) ...[
          const SizedBox(height: FormaSpacing.xs),
          Text(
            widget.errorText!,
            style:
                (isDark ? FormaTypography.captionDark : FormaTypography.caption)
                    .copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}
