import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/data/repositories/hydration_repository.dart';

/// Interactive modal to log real daily water intake.
class HydrationLogModal extends ConsumerWidget {
  const HydrationLogModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentWater = ref.watch(dailyHydrationProvider);
    const targetWater = HydrationRepository.dailyTargetMl;
    final fraction = (currentWater / targetWater).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: FormaColors.concreteGrey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Hydration',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Target: ${(targetWater / 1000).toStringAsFixed(1)}L per day',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Reset Water Today',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(dailyHydrationProvider.notifier).resetWater();
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Central Stat & Animated Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${(currentWater / 1000).toStringAsFixed(1)}',
                style:
                    const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 4),
              Text(
                'L',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? FormaColors.darkSecondaryText
                      : FormaColors.lightSecondaryText,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '(${(fraction * 100).toInt()}%)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: FormaColors.icyBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Horizontal Progress Capsule
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 14,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(FormaColors.icyBlue),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Increment Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildAddButton(
                  context,
                  ref,
                  label: '+250 ml',
                  sublabel: 'Glass',
                  amount: 250,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAddButton(
                  context,
                  ref,
                  label: '+500 ml',
                  sublabel: 'Bottle',
                  amount: 500,
                  isDark: isDark,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAddButton(
                  context,
                  ref,
                  label: '+750 ml',
                  sublabel: 'Large',
                  amount: 750,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String sublabel,
    required int amount,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(dailyHydrationProvider.notifier).addWater(amount);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? FormaColors.icyBlue
              : (isDark
                  ? FormaColors.darkSecondaryBackground
                  : FormaColors.lightSecondaryBackground),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPrimary
                ? FormaColors.icyBlue
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isPrimary
                    ? FormaColors.charcoal
                    : (isDark ? Colors.white : FormaColors.charcoal),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? FormaColors.charcoal.withValues(alpha: 0.7)
                    : (isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
