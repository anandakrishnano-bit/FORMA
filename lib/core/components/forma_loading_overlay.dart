import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/components/forma_logo.dart';

/// Aesthetic, fluid loading overlay with glowing animated rings
/// and cycling motivational status text.
class FormaLoadingOverlay extends StatefulWidget {
  final String title;
  final String? subtitle;

  const FormaLoadingOverlay({
    super.key,
    this.title = 'Authenticating...',
    this.subtitle,
  });

  @override
  State<FormaLoadingOverlay> createState() => _FormaLoadingOverlayState();
}

class _FormaLoadingOverlayState extends State<FormaLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  final List<String> _statusMessages = [
    'Creating your private FORMA profile...',
    'Securing daily habits & routines...',
    'Configuring personalized dashboard...',
    'Finalizing encrypted fitness vault...',
  ];
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    // Cycle messages every 1.5 seconds
    _cycleMessages();
  }

  void _cycleMessages() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _statusMessages.length;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.4),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: FormaColors.primaryAccent.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: FormaColors.primaryAccent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing concentric animated capsule ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: _pulseAnimation.value * 1.15,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: FormaColors.terracotta
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: FormaColors.primaryAccent
                                  .withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                        RotationTransition(
                          turns: _rotationAnimation,
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  FormaColors.terracotta,
                                  FormaColors.goldenYellow,
                                  FormaColors.sage,
                                  FormaColors.lavender,
                                  FormaColors.terracotta.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? FormaColors.charcoal
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const FormaLogo(
                          size: 26,
                          isCropped: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? FormaColors.darkPrimaryText
                            : FormaColors.lightPrimaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        widget.subtitle ?? _statusMessages[_messageIndex],
                        key: ValueKey<int>(_messageIndex),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
