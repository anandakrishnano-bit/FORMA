import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/bug_report/providers/bug_report_providers.dart';

/// Help & Support hub under Profile -> Settings.
class HelpAndSupportScreen extends ConsumerWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMaintainer = ref.watch(isMaintainerProvider);
    final myReportsAsync = ref.watch(myBugReportsProvider);
    final pendingCount = myReportsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Header Hero Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          FormaColors.darkCardBackground,
                          FormaColors.charcoal.withValues(alpha: 0.8),
                        ]
                      : [
                          FormaColors.lightCardBackground,
                          FormaColors.sage.withValues(alpha: 0.08),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: FormaColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: FormaColors.primaryAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'We are here to help',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? FormaColors.darkPrimaryText
                                : FormaColors.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Report issues, track investigations, or view system status.',
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Problem Reporting
            _buildSectionHeader('SUPPORT & REPORTING', isDark),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? FormaColors.darkCardBackground
                    : FormaColors.lightCardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.bug_report_rounded,
                        color: FormaColors.coralPink),
                    title: const Text(
                      'Report a Problem',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Describe a crash, visual glitch, or feature issue',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/profile/help/report-problem'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.assignment_turned_in_rounded,
                        color: FormaColors.goldenYellow),
                    title: const Text(
                      'My Reported Problems',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      pendingCount > 0
                          ? '$pendingCount report${pendingCount == 1 ? '' : 's'} on record'
                          : 'Track the status of your reports',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: FormaColors.goldenYellow
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: FormaColors.goldenYellow,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => context.push('/profile/help/my-reports'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Diagnostics & Legal
            _buildSectionHeader('DIAGNOSTICS & SYSTEM', isDark),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? FormaColors.darkCardBackground
                    : FormaColors.lightCardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.monitor_heart_rounded,
                        color: FormaColors.sage),
                    title: const Text(
                      'System Diagnostics',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Verify Firebase, Health Connect & network status',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/developer-diagnostics'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined,
                        color: FormaColors.primaryAccent),
                    title: const Text(
                      'Terms and Conditions',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Privacy policy and service agreement',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/terms-and-conditions'),
                  ),
                ],
              ),
            ),

            // Section: Maintainer Developer Tools (Visible to authorized maintainers)
            if (isMaintainer) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('MAINTAINER TOOLS', isDark),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.darkCardBackground
                      : FormaColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: FormaColors.coralPink.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings_rounded,
                      color: FormaColors.coralPink),
                  title: const Text(
                    'Bug Investigation Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: FormaColors.coralPink,
                    ),
                  ),
                  subtitle: const Text(
                    'Review all user reports, stack traces & screenshots',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/help/maintainer-reports'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: isDark
              ? FormaColors.darkSecondaryText
              : FormaColors.lightSecondaryText,
        ),
      ),
    );
  }
}
