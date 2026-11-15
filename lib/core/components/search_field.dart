import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

class FormaSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const FormaSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkSecondaryBackground
            : FormaColors.lightSecondaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark
              ? FormaColors.darkPrimaryText
              : FormaColors.lightPrimaryText,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark
                ? FormaColors.darkSecondaryText
                : FormaColors.lightSecondaryText,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
