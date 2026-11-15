import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

class FormaLoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const FormaLoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  State<FormaLoadingSkeleton> createState() => _FormaLoadingSkeletonState();
}

class _FormaLoadingSkeletonState extends State<FormaLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Color.lerp(
              isDark
                  ? FormaColors.charcoal
                  : FormaColors.lightSecondaryBackground,
              isDark
                  ? FormaColors.darkSecondaryBackground
                  : FormaColors.concreteGrey.withValues(alpha: 0.2),
              _controller.value,
            ),
          ),
        );
      },
    );
  }
}
