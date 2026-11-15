import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:forma/core/components/universal_quick_add_fab.dart';
import 'package:forma/core/theme/app_colors.dart';

/// Shell scaffold that wraps the app content with the custom floating
/// sculpted organic bottom navigation bar.
///
/// CRITICAL ARCHITECTURAL GUARANTEE:
/// The navigation bar is placed inside a Stack outside and above the scrollable content.
/// It never bounces, stretches, clips, or moves in response to page scrolling.
class FormaShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const FormaShellScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (navigationShell.currentIndex != 0) {
          HapticFeedback.lightImpact();
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 1. Core Shell Content (preserves full scroll & widget state across tabs)
            Positioned.fill(
              child: navigationShell,
            ),

            // 2. Universal Quick-Add FAB
            Positioned(
              right: 20,
              bottom: (MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom + 8
                      : 16) +
                  72,
              child: const UniversalQuickAddFab(),
            ),

            // 3. Custom floating bottom navigation bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FormaFloatingNavBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) {
                  if (index != navigationShell.currentIndex) {
                    HapticFeedback.lightImpact();
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab representation
class _NavDestination {
  final IconData icon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.label,
  });
}

/// Custom Floating Organic Sculpted Navigation Bar
///
/// Direct fidelity implementation of the reference design:
/// - Distinctive 3-lobed sculpted organic silhouette:
///   [ Left Pill (Tabs 0 & 1) ] -> [ Smooth Pinched Waist ] -> ( Circular Center Node Tab 2 ) -> [ Smooth Pinched Waist ] -> [ Right Pill (Tabs 3 & 4) ]
/// - Deep charcoal obsidian background (#171719).
/// - Floating ambient drop shadow for realistic elevation.
/// - Prominent white circular pill indicator for the active tab that smoothly slides and morphs.
/// - High-contrast white line icons on inactive tabs and dark charcoal icon on active tab.
/// - Fixed Stack overlay; strictly independent of page scrolling.
class FormaFloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FormaFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FormaFloatingNavBar> createState() => _FormaFloatingNavBarState();
}

class _FormaFloatingNavBarState extends State<FormaFloatingNavBar> {
  static const List<_NavDestination> _destinations = [
    _NavDestination(icon: LucideIcons.home, label: 'Home'),
    _NavDestination(icon: LucideIcons.dumbbell, label: 'Workouts'),
    _NavDestination(icon: LucideIcons.apple, label: 'Nutrition'),
    _NavDestination(icon: LucideIcons.barChart3, label: 'Habits'),
    _NavDestination(icon: LucideIcons.wallet, label: 'Expenses'),
  ];

  bool _isMorphing = false;

  @override
  void didUpdateWidget(covariant FormaFloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      setState(() => _isMorphing = true);
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => _isMorphing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    // Fixed width calculation ensuring responsive margins across phones
    final barWidth = (screenWidth - 36).clamp(320.0, 420.0);
    const barHeight = 64.0;
    const circleSize = 52.0;
    final itemWidth = barWidth / _destinations.length;
    final indicatorWidth = _isMorphing ? circleSize * 1.25 : circleSize;
    final indicatorHeight = _isMorphing ? circleSize * 0.90 : circleSize;

    return Padding(
      // Keep clear space above Android system navigation / gestures
      padding: EdgeInsets.only(
        left: (screenWidth - barWidth) / 2,
        right: (screenWidth - barWidth) / 2,
        bottom: bottomInset > 0 ? bottomInset + 8 : 16,
      ),
      child: SizedBox(
        width: barWidth,
        height: barHeight,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Sculpted Organic Silhouette Background with Depth Shadow
            CustomPaint(
              size: Size(barWidth, barHeight),
              painter: _SculptedNavBarPainter(
                color: FormaColors.charcoal,
                shadowColor: Colors.black.withValues(alpha: 0.35),
              ),
            ),

            // 2. Animated Floating Active Indicator (Morphing white selection circle / pill)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.fastEaseInToSlowEaseOut,
              left: (widget.currentIndex * itemWidth) +
                  (itemWidth - indicatorWidth) / 2,
              top: (barHeight - indicatorHeight) / 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: indicatorWidth,
                height: indicatorHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(circleSize / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: _isMorphing ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Navigation Interactive Icons Row
            Positioned.fill(
              child: Row(
                children: List.generate(_destinations.length, (index) {
                  final isSelected = widget.currentIndex == index;
                  final destination = _destinations[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onTap(index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 260),
                          scale: isSelected ? 1.14 : 1.0,
                          curve: Curves.easeOutBack,
                          child: Icon(
                            destination.icon,
                            size: 22,
                            color: isSelected
                                ? FormaColors.charcoal
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter rendering the organic sculpted silhouette seen in the reference image:
///
/// - Left Pill (enclosing Tabs 0 & 1): rounded end cap and smooth horizontal profile.
/// - Concave Waist 1: smoothly pinches inward between Tab 1 and Tab 2.
/// - Center Circular Node (Tab 2): circular outward swell creating the iconic action hub.
/// - Concave Waist 2: smoothly pinches inward between Tab 2 and Tab 3.
/// - Right Pill (enclosing Tabs 3 & 4): smooth horizontal profile and rounded end cap.
class _SculptedNavBarPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _SculptedNavBarPainter({
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = h / 2; // Semi-circular cap radius (32.0 for h=64)

    final itemWidth = w / 5;
    // Midpoint between Tab 1 and Tab 2
    final w1 = itemWidth * 2;
    // Midpoint between Tab 2 and Tab 3
    final w2 = itemWidth * 3;
    // Center point of Tab 2 (the circular hub)
    final c2 = itemWidth * 2.5;

    // Waist geometry
    const transitionDx = 22.0; // Half-width of transition into the waist
    const pinchDepth = 14.5; // Depth of waist inward curves
    const pinchTop = pinchDepth;
    final pinchBottom = h - pinchDepth;

    final path = Path();

    // 1. Top left pill start (at top of left circular cap)
    path.moveTo(r, 0);

    // 2. Straight horizontal top of left pill (Tabs 0 & 1)
    path.lineTo(w1 - transitionDx, 0);

    // 3. Smooth concave descent into waist 1
    path.cubicTo(
      w1 - (transitionDx * 0.45),
      0,
      w1 - (transitionDx * 0.45),
      pinchTop,
      w1,
      pinchTop,
    );

    // 4. Smooth convex ascent up to the apex of the center circular node (Tab 2)
    path.cubicTo(
      w1 + ((c2 - w1) * 0.45),
      pinchTop,
      c2 - ((c2 - w1) * 0.45),
      0,
      c2,
      0,
    );

    // 5. Smooth convex descent from center circular node down into waist 2
    path.cubicTo(
      c2 + ((w2 - c2) * 0.45),
      0,
      w2 - ((w2 - c2) * 0.45),
      pinchTop,
      w2,
      pinchTop,
    );

    // 6. Smooth concave ascent from waist 2 to the top of the right pill
    path.cubicTo(
      w2 + (transitionDx * 0.45),
      pinchTop,
      w2 + (transitionDx * 0.45),
      0,
      w2 + transitionDx,
      0,
    );

    // 7. Straight horizontal top of right pill (Tabs 3 & 4)
    path.lineTo(w - r, 0);

    // 8. Right circular cap (semi-circle)
    path.arcToPoint(
      Offset(w - r, h),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 9. Straight horizontal bottom of right pill
    path.lineTo(w2 + transitionDx, h);

    // 10. Smooth concave ascent into waist 2 (bottom)
    path.cubicTo(
      w2 + (transitionDx * 0.45),
      h,
      w2 + (transitionDx * 0.45),
      pinchBottom,
      w2,
      pinchBottom,
    );

    // 11. Smooth convex descent to the bottom apex of center circular node (Tab 2)
    path.cubicTo(
      w2 - ((w2 - c2) * 0.45),
      pinchBottom,
      c2 + ((w2 - c2) * 0.45),
      h,
      c2,
      h,
    );

    // 12. Smooth convex ascent from center circular node up to waist 1 (bottom)
    path.cubicTo(
      c2 - ((c2 - w1) * 0.45),
      h,
      w1 + ((c2 - w1) * 0.45),
      pinchBottom,
      w1,
      pinchBottom,
    );

    // 13. Smooth concave descent from waist 1 to bottom of left pill
    path.cubicTo(
      w1 - (transitionDx * 0.45),
      pinchBottom,
      w1 - (transitionDx * 0.45),
      h,
      w1 - transitionDx,
      h,
    );

    // 14. Straight horizontal bottom of left pill
    path.lineTo(r, h);

    // 15. Left circular cap (semi-circle)
    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
      clockwise: true,
    );

    path.close();

    // Draw ambient floating depth shadow
    canvas.drawShadow(path, shadowColor, 14, false);

    // Draw solid charcoal body
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SculptedNavBarPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
  }
}
