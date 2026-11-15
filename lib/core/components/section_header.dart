import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

class FormaSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FormaSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark
                ? FormaColors.darkPrimaryText
                : FormaColors.lightPrimaryText,
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FormaColors.primaryAccent,
              ),
            ),
          ),
      ],
    );
  }
}
