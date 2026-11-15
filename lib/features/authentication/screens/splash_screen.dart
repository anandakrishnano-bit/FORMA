import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/components/forma_logo.dart';

/// Full-screen splash with an organic, continuous branded opening animation.
/// Seamlessly matches Android's native splash theme (Dark / Light) with zero color flash,
/// blooms the FORMA mark, and restores the user session without jarring double-splash effects.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _letterSpacingAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Smooth opening / bloom curve
    _scaleAnimation = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _letterSpacingAnimation = Tween<double>(begin: 2.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );

    _animController.forward();

    // Responsive startup session resolution
    Future.delayed(const Duration(milliseconds: 950), _checkSessionAndNavigate);
  }

  Future<void> _checkSessionAndNavigate() async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (mounted) context.go('/home');
      } else {
        if (mounted) context.go('/welcome');
      }
    } catch (_) {
      if (mounted) context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? FormaColors.darkBackground : FormaColors.warmCream;
    final primaryTextColor =
        isDark ? FormaColors.darkPrimaryText : FormaColors.charcoal;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.concreteGrey;

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Animated Opening Logo with Radiant Glow Ring ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle ambient glow expanding as logo opens
                    Transform.scale(
                      scale: 1.0 + (_glowAnimation.value * 0.28),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: FormaColors.goldenYellow.withValues(
                            alpha: 0.16 * (1.0 - _glowAnimation.value * 0.4),
                          ),
                        ),
                      ),
                    ),
                    // Scale & fade opening FORMA mark
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: const FormaLogo(
                          size: 96,
                          isCropped: false,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Animated Letter-Spacing Brand Title ──
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'FORMA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: primaryTextColor,
                      letterSpacing: _letterSpacingAnimation.value,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Smooth Subtitle ──
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Make every day count.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                      letterSpacing: 0.4,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
