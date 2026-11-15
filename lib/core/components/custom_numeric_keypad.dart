import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/theme/app_colors.dart';

/// A spacious, tactile custom numeric keypad inspired by the Pakee reference.
///
/// Features:
/// - 3-column numeric layout with large, comfortable touch targets
/// - Decimal separator (.), backspace (⌫), and done (✓)
/// - Input validation (prevents multiple decimals, limits to 2 decimal places)
/// - Smooth opening/closing panel animation
/// - Accessible toggle to standard Android system keyboard
/// - Haptic feedback on tap
class CustomNumericKeypad extends StatelessWidget {
  final ValueNotifier<String> amountNotifier;
  final VoidCallback? onDone;
  final VoidCallback? onSwitchToSystemKeyboard;
  final bool showDoneButton;
  final bool isDark;

  const CustomNumericKeypad({
    super.key,
    required this.amountNotifier,
    this.onDone,
    this.onSwitchToSystemKeyboard,
    this.showDoneButton = true,
    this.isDark = true,
  });

  void _handleKeyTap(String key) {
    HapticFeedback.selectionClick();
    final current = amountNotifier.value;

    if (key == 'backspace') {
      if (current.isNotEmpty) {
        amountNotifier.value = current.substring(0, current.length - 1);
      }
      return;
    }

    if (key == 'clear') {
      amountNotifier.value = '';
      return;
    }

    if (key == '.') {
      if (current.contains('.')) return; // Prevent multiple dots
      if (current.isEmpty) {
        amountNotifier.value = '0.';
      } else {
        amountNotifier.value = '$current.';
      }
      return;
    }

    // Number entered
    // If there's already a decimal point, limit to 2 decimal places
    if (current.contains('.')) {
      final parts = current.split('.');
      if (parts.length > 1 && parts[1].length >= 2) {
        return; // Max 2 decimals
      }
    }

    // Limit maximum integer digits to 9 (e.g. 999,999,999)
    if (!current.contains('.') && current.length >= 9) {
      return;
    }

    if (current == '0') {
      amountNotifier.value = key;
    } else {
      amountNotifier.value = '$current$key';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? FormaColors.charcoal : FormaColors.warmCream;
    final buttonBg = isDark ? const Color(0xFF232328) : Colors.white;
    final textColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Toolbar: switch to keyboard & clear button
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onSwitchToSystemKeyboard != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onSwitchToSystemKeyboard?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: buttonBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.keyboard_outlined,
                                size: 16, color: secondaryTextColor),
                            const SizedBox(width: 6),
                            Text(
                              'Standard Keyboard',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  GestureDetector(
                    onTap: () => _handleKeyTap('clear'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: buttonBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: FormaColors.coralPink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Keypad Grid: 4 rows x 3 columns
            _buildRow(['1', '2', '3'], buttonBg, textColor),
            const SizedBox(height: 10),
            _buildRow(['4', '5', '6'], buttonBg, textColor),
            const SizedBox(height: 10),
            _buildRow(['7', '8', '9'], buttonBg, textColor),
            const SizedBox(height: 10),
            Row(
              children: [
                // Decimal Key
                Expanded(
                  child: _KeyButton(
                    onTap: () => _handleKeyTap('.'),
                    backgroundColor: buttonBg,
                    child: Text(
                      '•',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Zero Key
                Expanded(
                  child: _KeyButton(
                    onTap: () => _handleKeyTap('0'),
                    backgroundColor: buttonBg,
                    child: Text(
                      '0',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Backspace or Done
                Expanded(
                  child: _KeyButton(
                    onTap: () => _handleKeyTap('backspace'),
                    backgroundColor: isDark
                        ? const Color(0xFF2C2528)
                        : const Color(0xFFFFECEF),
                    child: const Icon(
                      Icons.backspace_outlined,
                      size: 22,
                      color: FormaColors.coralPink,
                    ),
                  ),
                ),
              ],
            ),

            // Optional Done / Confirm Action Bar
            if (showDoneButton) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onDone?.call();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: FormaColors.goldenYellow,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: FormaColors.goldenYellow.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: FormaColors.charcoal, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm Amount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: FormaColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys, Color buttonBg, Color textColor) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _KeyButton(
              onTap: () => _handleKeyTap(key),
              backgroundColor: buttonBg,
              child: Text(
                key,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Widget child;

  const _KeyButton({
    required this.onTap,
    required this.backgroundColor,
    required this.child,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _animController.forward(),
      onTapUp: (_) {
        _animController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
