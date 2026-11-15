import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/legal/terms_data.dart';
import 'package:forma/core/theme/app_colors.dart';

/// Scrollable, readable, and fully styled Terms and Conditions Screen.
/// Works 100% offline via local bundled terms data.
class TermsAndConditionsScreen extends StatelessWidget {
  final bool showAcceptButton;
  final VoidCallback? onAccept;

  const TermsAndConditionsScreen({
    super.key,
    this.showAcceptButton = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? FormaColors.darkBackground : FormaColors.lightBackground;
    final cardColor = isDark
        ? FormaColors.darkCardBackground
        : FormaColors.lightCardBackground;
    final primaryTextColor = isDark ? Colors.white : FormaColors.charcoal;
    final secondaryTextColor =
        isDark ? FormaColors.darkSecondaryText : FormaColors.lightSecondaryText;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: primaryTextColor),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Terms & Conditions',
            style: GoogleFonts.plusJakartaSans(
              color: primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'v${FormaTermsData.currentVersion}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FormaColors.primaryAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Metadata Banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : FormaColors.divider.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel_rounded,
                      size: 20, color: FormaColors.primaryAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official Legal Agreement',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Effective: ${FormaTermsData.effectiveDate} • Last Updated: ${FormaTermsData.lastUpdatedDate}',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Terms Content
            Expanded(
              child: Markdown(
                data: FormaTermsData.fullTermsMarkdown,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                styleSheet: MarkdownStyleSheet(
                  h1: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    height: 1.4,
                  ),
                  h2: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: FormaColors.primaryAccent,
                    height: 1.4,
                  ),
                  h3: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                    height: 1.5,
                  ),
                  p: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.6,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.88)
                        : const Color(0xFF2C2C2E),
                  ),
                  listBullet: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: FormaColors.primaryAccent,
                  ),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                        width: 1,
                      ),
                    ),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(
                          color: FormaColors.primaryAccent, width: 4),
                    ),
                  ),
                ),
              ),
            ),

            // Optional Acceptance Footer
            if (showAcceptButton)
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                ),
                child: FormaButton(
                  label: 'I Agree & Continue',
                  onPressed: onAccept,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
