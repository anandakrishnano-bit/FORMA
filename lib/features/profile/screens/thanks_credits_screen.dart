import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/components/forma_logo.dart';

/// Dedicated "Thanks & Credits" screen introducing the developer and technology stack.
///
/// Route: /thanks-credits
class ThanksCreditsScreen extends StatelessWidget {
  const ThanksCreditsScreen({super.key});

  Future<void> _openUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $urlString'),
            backgroundColor: FormaColors.coralPink,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white : FormaColors.charcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Central Brand Header
              Center(
                child: Column(
                  children: [
                    const FormaLogo(
                      size: 72,
                      isCropped: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Made with care.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: isDark
                            ? FormaColors.darkPrimaryText
                            : FormaColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thanks for being part of FORMA.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Developer Profile Card
              const Text(
                'DEVELOPER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: FormaColors.concreteGrey,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.darkCardBackground
                      : FormaColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: FormaColors.goldenYellow,
                          ),
                          child: const Center(
                            child: Text(
                              'AK',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: FormaColors.charcoal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ananda Krishnan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? FormaColors.darkPrimaryText
                                    : FormaColors.lightPrimaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lead Developer & Designer',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? FormaColors.darkSecondaryText
                                    : FormaColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Social Links
                    _buildSocialRow(
                      context: context,
                      platformName: 'GitHub',
                      handle: '@anandakrishnano-bit',
                      icon: Icons.code_rounded,
                      iconColor: isDark ? Colors.white : FormaColors.charcoal,
                      url: 'https://github.com/anandakrishnano-bit',
                    ),
                    const SizedBox(height: 8),

                    _buildSocialRow(
                      context: context,
                      platformName: 'LinkedIn',
                      handle: 'ananda-krishnan-o',
                      icon: Icons.work_rounded,
                      iconColor: const Color(0xFF0A66C2),
                      url:
                          'https://www.linkedin.com/in/ananda-krishnan-o-a2233337a/',
                    ),
                    const SizedBox(height: 8),

                    _buildSocialRow(
                      context: context,
                      platformName: 'Instagram',
                      handle: '@ak_its_m3',
                      icon: Icons.camera_alt_rounded,
                      iconColor: const Color(0xFFE4405F),
                      url: 'https://www.instagram.com/ak_its_m3/',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Built With Section
              const Text(
                'BUILT WITH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: FormaColors.concreteGrey,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.darkCardBackground
                      : FormaColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildTechRow(
                        'Flutter',
                        'Cross-platform reactive UI framework',
                        Icons.flutter_dash_rounded,
                        FormaColors.azure),
                    const Divider(height: 16),
                    _buildTechRow(
                        'Firebase',
                        'Authentication, Firestore & Security',
                        Icons.local_fire_department_rounded,
                        const Color(0xFFFFA000)),
                    const Divider(height: 16),
                    _buildTechRow(
                        'Google Health Connect',
                        'Android physical activity & metrics sync',
                        Icons.health_and_safety_rounded,
                        FormaColors.sage),
                    const Divider(height: 16),
                    _buildTechRow(
                        'Gemini AI',
                        'Personal coaching & grounded daily recaps',
                        Icons.auto_awesome_rounded,
                        FormaColors.goldenYellow),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Footer: "Made with AI & love."
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Made with AI & love.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isDark
                                ? FormaColors.darkPrimaryText
                                : FormaColors.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded,
                            size: 14, color: FormaColors.goldenYellow),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'FORMA v1.0.0 (Build 1)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? FormaColors.darkSecondaryText
                            : FormaColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialRow({
    required BuildContext context,
    required String platformName,
    required String handle,
    required IconData icon,
    required Color iconColor,
    required String url,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openUrl(context, url),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platformName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? FormaColors.darkPrimaryText
                          : FormaColors.lightPrimaryText,
                    ),
                  ),
                  Text(
                    handle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? FormaColors.darkSecondaryText
                          : FormaColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                size: 16, color: FormaColors.concreteGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildTechRow(
      String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: FormaColors.concreteGrey)),
            ],
          ),
        ),
      ],
    );
  }
}
