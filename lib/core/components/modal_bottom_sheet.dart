import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';

/// Global reusable modal bottom sheet pattern for FORMA.
/// Guarantees:
/// 1. `useRootNavigator: true` so modals always render in front of floating bottom navigation bar.
/// 2. `SafeArea(bottom: true)` with keyboard insets padding so confirmation buttons are never hidden behind navigation bars or soft keyboards.
/// 3. Standard layout architecture:
///    - Centered pill drag handle.
///    - Optional header with title & close button.
///    - Scrollable flexible body.
///    - Persistent sticky footer pinned to bottom for primary action buttons.
class FormaModalSheet {
  const FormaModalSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? leading,
    List<Widget>? headerActions,
    required Widget child,
    Widget? stickyFooter,
    bool isDismissible = true,
    bool enableDrag = true,
    double maxContentHeightFactor = 0.88,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      useRootNavigator: true, // Always in front of floating capsule nav bar
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final mediaQuery = MediaQuery.of(ctx);
        final bottomInset = mediaQuery.viewInsets.bottom;
        final maxHeight = mediaQuery.size.height * maxContentHeightFactor;

        return AnimatedPadding(
          padding: EdgeInsets.only(bottom: bottomInset),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: SafeArea(
            bottom: true,
            top: false,
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Drag Handle
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: FormaColors.concreteGrey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Optional Header
                  if (title != null || leading != null || headerActions != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Row(
                        children: [
                          if (leading != null) ...[
                            leading,
                            const SizedBox(width: 10),
                          ],
                          if (title != null)
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          if (headerActions != null) ...headerActions,
                        ],
                      ),
                    ),

                  // 3. Scrollable Flexible Body
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: child,
                    ),
                  ),

                  // 4. Persistent Sticky Footer (Buttons ALWAYS visible & clickable)
                  if (stickyFooter != null)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? FormaColors.charcoal
                            : FormaColors.warmCream,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.white10
                                : FormaColors.divider.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                      ),
                      child: stickyFooter,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Backward compatible alias
typedef FormaBottomSheet = FormaModalSheet;
