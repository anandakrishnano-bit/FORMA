import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/components/hydration_log_modal.dart';
import 'package:forma/core/theme/app_colors.dart';

/// Universal Quick-Add Floating Action Button for FORMA.
///
/// Provides rapid 1-tap logging across:
/// 1. Log Workout
/// 2. Log Meal / Food
/// 3. Track Habit
/// 4. Add Personal Expense
/// 5. Add Shared Expense
/// 6. Quick Hydration (+250ml)
class UniversalQuickAddFab extends StatefulWidget {
  const UniversalQuickAddFab({super.key});

  @override
  State<UniversalQuickAddFab> createState() => _UniversalQuickAddFabState();
}

class _UniversalQuickAddFabState extends State<UniversalQuickAddFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showQuickAddSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    _controller.forward();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickAddActionSheet(
        onDismiss: () => _controller.reverse(),
      ),
    ).then((_) {
      if (mounted) _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormaBounceable(
      onTap: () => _showQuickAddSheet(context),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: FormaColors.goldenYellow,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: FormaColors.goldenYellow.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.125).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: FormaColors.charcoal,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddActionSheet extends StatelessWidget {
  final VoidCallback onDismiss;

  const _QuickAddActionSheet({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      _QuickAction(
        title: 'Log Workout',
        subtitle: 'Record an active training session',
        icon: Icons.fitness_center_rounded,
        iconColor: FormaColors.coralPink,
        onTap: () {
          Navigator.of(context).pop();
          context.push('/workout/manual-log');
        },
      ),
      _QuickAction(
        title: 'Log Meal / Food',
        subtitle: 'Track calories and macronutrients',
        icon: Icons.restaurant_rounded,
        iconColor: FormaColors.goldenYellow,
        onTap: () {
          Navigator.of(context).pop();
          context.push('/nutrition');
        },
      ),
      _QuickAction(
        title: 'Track Habits',
        subtitle: 'Check in on daily routines',
        icon: Icons.check_circle_outline_rounded,
        iconColor: FormaColors.secondaryAccent,
        onTap: () {
          Navigator.of(context).pop();
          context.push('/habits');
        },
      ),
      _QuickAction(
        title: 'Add Personal Expense',
        subtitle: 'Private personal spending record',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: FormaColors.semanticSteps,
        onTap: () {
          Navigator.of(context).pop();
          context.push('/expenses/add');
        },
      ),
      _QuickAction(
        title: 'Add Shared Expense',
        subtitle: 'Split bill with friends or group',
        icon: Icons.group_add_rounded,
        iconColor: const Color(0xFF6B7280),
        onTap: () {
          Navigator.of(context).pop();
          context.push('/expenses/shared/add');
        },
      ),
      _QuickAction(
        title: 'Quick Hydration',
        subtitle: 'Log water intake (+250ml)',
        icon: Icons.water_drop_rounded,
        iconColor: const Color(0xFF3B82F6),
        onTap: () {
          Navigator.of(context).pop();
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (c) => const HydrationLogModal(),
          );
        },
      ),
    ];

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? FormaColors.charcoal : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Add',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Action Tiles Grid
              ...actions.map((act) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FormaBounceable(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        act.onTap();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF7F5F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : FormaColors.divider.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: act.iconColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(act.icon,
                                  size: 20, color: act.iconColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    act.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    act.subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? FormaColors.darkSecondaryText
                                          : FormaColors.lightSecondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: FormaColors.concreteGrey),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}
