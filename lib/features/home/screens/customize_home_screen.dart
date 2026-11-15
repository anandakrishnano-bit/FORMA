import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/features/home/models/home_card_config.dart';
import 'package:forma/features/home/repositories/home_customization_repository.dart';

/// Screen allowing users to customize their FORMA Home Screen layout:
/// - Drag-and-drop card reordering
/// - Toggle card visibility (show/hide)
/// - Reset to default editorial layout
/// - Automatic local + cloud synchronization
class CustomizeHomeScreen extends ConsumerWidget {
  const CustomizeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = ref.watch(homeCardConfigsProvider);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor:
            isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Home',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            'Customize Home',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
          TextButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await ref.read(homeCardConfigsProvider.notifier).resetToDefault();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Layout reset to default.'),
                    duration: Duration(seconds: 2),
                    backgroundColor: FormaColors.charcoal,
                  ),
                );
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: FormaColors.coralPink),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organize Your Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Drag the handle on any card to reposition it, or toggle visibility to keep your home feed focused.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: cards.length,
                // ignore: deprecated_member_use
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.lightImpact();
                  ref
                      .read(homeCardConfigsProvider.notifier)
                      .reorder(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return _buildCardItem(
                    key: ValueKey(card.id),
                    card: card,
                    isDark: isDark,
                    onToggle: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(homeCardConfigsProvider.notifier)
                          .toggleVisibility(card.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildCardItem({
    required Key key,
    required HomeCardConfig card,
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: card.isVisible
              ? (isDark
                  ? Colors.white12
                  : FormaColors.divider.withValues(alpha: 0.6))
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drag handle
          const Icon(
            Icons.drag_indicator_rounded,
            color: FormaColors.concreteGrey,
            size: 24,
          ),
          const SizedBox(width: 12),

          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: card.isVisible
                  ? FormaColors.goldenYellow.withValues(alpha: 0.18)
                  : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              card.icon,
              size: 20,
              color: card.isVisible
                  ? FormaColors.goldenYellow
                  : FormaColors.concreteGrey,
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: card.isVisible
                        ? (isDark
                            ? FormaColors.darkPrimaryText
                            : FormaColors.lightPrimaryText)
                        : FormaColors.concreteGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Toggle visibility switch
          Switch.adaptive(
            value: card.isVisible,
            activeThumbColor: FormaColors.goldenYellow,
            activeTrackColor: FormaColors.goldenYellow.withValues(alpha: 0.4),
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}
