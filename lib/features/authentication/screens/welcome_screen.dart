import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/components/forma_logo.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';

/// Screen 1: Welcome
///
/// Features:
/// - Official FORMA logo with an elegant subtle entrance animation.
/// - Clean, spacious editorial layout in warm cream and charcoal.
/// - Memorable introduction: "Make every day count."
/// - Visually distinct "Get Started" (Primary) and "I already have an account" (Secondary) actions.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topHeight = screenHeight * 0.58;

    return Scaffold(
      backgroundColor: FormaColors.charcoal,
      body: Column(
        children: [
          // ──────────────── Charcoal Top Section with Logo & Message ────────────────
          SizedBox(
            height: topHeight,
            width: double.infinity,
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    color: FormaColors.charcoal,
                  ),
                ),

                // Subtle icy blue atmospheric glow in top right
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FormaColors.icyBlue.withValues(alpha: 0.08),
                    ),
                  ),
                ),

                // Subtle coral accent glow in bottom left
                Positioned(
                  bottom: -60,
                  left: -60,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FormaColors.coralPink.withValues(alpha: 0.06),
                    ),
                  ),
                ),

                // Content
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FormaSpacing.xl,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: FormaSpacing.lg),

                            // Official Logo row with subtle scale
                            ScaleTransition(
                              scale: _scaleAnimation,
                              alignment: Alignment.centerLeft,
                              child: const FormaLogo(
                                size: 42,
                                showWordmark: true,
                                wordmarkColor: Colors.white,
                                wordmarkSize: 22,
                                isCropped: false,
                              ),
                            ),

                            const Spacer(),

                            // Editorial heading
                            Text(
                              'Make every day count.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: FormaSpacing.md),

                            // Supporting text
                            Text(
                              'Your space to build better routines, track your progress, and stay organised.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: FormaColors.concreteGrey,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: FormaSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ──────────────── Warm Cream Action Section ────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: FormaColors.warmCream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: FormaSpacing.xl,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Primary Action: Get Started
                    FormaBounceable(
                      onTap: () => context.push('/onboarding-flow'),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: FormaColors.charcoal,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: FormaSpacing.md),

                    // Secondary Action: I already have an account
                    FormaBounceable(
                      onTap: () => context.push('/login'),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: FormaColors.charcoal.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'I already have an account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: FormaColors.charcoal,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Privacy & Terms Note
                    Padding(
                      padding: const EdgeInsets.only(bottom: FormaSpacing.md),
                      child: Text(
                        'By continuing you agree to FORMA’s Terms & Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: FormaColors.concreteGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
