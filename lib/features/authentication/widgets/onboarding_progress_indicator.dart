import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';

/// Horizontal step indicator for the onboarding flow.
///
/// Displays a row of dots — filled for completed steps, a larger
/// accent-coloured dot for the current step, and grey dots for remaining.
class OnboardingProgressIndicator extends StatelessWidget {
  /// Total number of onboarding steps.
  final int totalSteps;

  /// Zero-based index of the current step.
  final int currentStep;

  const OnboardingProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final colors = FormaColors.light;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isCompleted
                ? colors.primaryAccent
                : isCurrent
                    ? colors.primaryAccent
                    : FormaColors.concreteGrey.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(FormaRadius.pill),
          ),
        );
      }),
    );
  }
}
