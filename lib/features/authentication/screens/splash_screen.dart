import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/components/forma_logo.dart';

/// Full-screen splash with smooth branded FORMA fade.
/// Restores persistent authentication session and navigates directly to /home
/// if already signed in, avoiding redundant logins on every restart.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Fast, responsive startup check
    Future.delayed(const Duration(milliseconds: 900), _checkSessionAndNavigate);
  }

  Future<void> _checkSessionAndNavigate() async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Authenticated user: restore session and go straight to Home
        if (mounted) context.go('/home');
      } else {
        // First launch or signed out: go to Welcome
        if (mounted) context.go('/welcome');
      }
    } catch (_) {
      if (mounted) context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormaColors.warmCream,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Official FORMA Brand Logo ──
              const FormaLogo(
                size: 96,
                isCropped: false,
              ),
              const SizedBox(height: 20),

              // ── App name ──
              Text(
                'FORMA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: FormaColors.charcoal,
                  letterSpacing: 6,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 6),

              // ── Subtitle ──
              Text(
                'Train. Track. Improve. Together.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FormaColors.concreteGrey,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
