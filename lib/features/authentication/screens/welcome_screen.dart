import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/theme/app_spacing.dart';
import 'package:forma/core/components/forma_logo.dart';

/// Two-tone welcome screen.
///
/// Top 60 %: charcoal dark section with large branding text.
/// Bottom 40 %: warm cream section with "Get Started" and "Sign In" CTAs.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topHeight = screenHeight * 0.6;

    return Scaffold(
      body: Column(
        children: [
          // ──────────────── Dark Top Section ────────────────
          SizedBox(
            height: topHeight,
            width: double.infinity,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: const BoxDecoration(
                    color: FormaColors.charcoal,
                  ),
                ),

                // Subtle gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FormaColors.charcoal,
                        FormaColors.charcoal.withValues(alpha: 0.95),
                        const Color(0xFF1E1E22),
                      ],
                    ),
                  ),
                ),

                // Accent geometric element (top-right)
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FormaColors.light.primaryAccent
                          .withValues(alpha: 0.08),
                    ),
                  ),
                ),

                // Another accent circle (bottom-left)
                Positioned(
                  bottom: -40,
                  left: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FormaColors.light.secondaryAccent
                          .withValues(alpha: 0.06),
                    ),
                  ),
                ),

                // Content
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FormaSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: FormaSpacing.xl),

                        // Official Logo row
                        const FormaLogo(
                          size: 38,
                          showWordmark: true,
                          wordmarkColor: Colors.white,
                          wordmarkSize: 22,
                        ),

                        const Spacer(),

                        // Editorial heading
                        Text(
                          'Your\nfitness\njourney\nstarts here.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: FormaSpacing.md),
                        Text(
                          'Train smarter, together.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: FormaColors.concreteGrey,
                          ),
                        ),
                        const SizedBox(height: FormaSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ──────────────── Warm Cream Bottom Section ────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              color: FormaColors.warmCream,
              padding: const EdgeInsets.symmetric(
                horizontal: FormaSpacing.lg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => context.push('/onboarding-flow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FormaColors.charcoal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: FormaRadius.borderRadiusLg,
                        ),
                        elevation: 0,
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Get Started'),
                    ),
                  ),
                  const SizedBox(height: FormaSpacing.md),

                  // Sign In text button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () => context.push('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: FormaColors.charcoal,
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: FormaRadius.borderRadiusLg,
                          side: BorderSide(
                            color: FormaColors.charcoal.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      child: const Text('I already have an account'),
                    ),
                  ),

                  const Spacer(),

                  // Terms
                  Padding(
                    padding: const EdgeInsets.only(bottom: FormaSpacing.lg),
                    child: Text(
                      'By continuing you agree to our Terms of Service\nand Privacy Policy',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: FormaColors.light.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
