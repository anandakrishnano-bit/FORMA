import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/services/app_logger.dart';
import 'package:forma/core/services/backend_verification_service.dart';
import 'package:forma/core/theme/app_colors.dart';

class DeveloperSetupDiagnosticsScreen extends StatefulWidget {
  const DeveloperSetupDiagnosticsScreen({super.key});

  @override
  State<DeveloperSetupDiagnosticsScreen> createState() =>
      _DeveloperSetupDiagnosticsScreenState();
}

class _DeveloperSetupDiagnosticsScreenState
    extends State<DeveloperSetupDiagnosticsScreen> {
  final BackendVerificationService _verifier = BackendVerificationService();
  List<ServiceHealth> _checks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);
    final results = await _verifier.runFullDiagnostics();
    if (mounted) {
      setState(() {
        _checks = results;
        _isLoading = false;
      });
    }
  }

  void _copyLogsToClipboard() {
    final export = AppLogger.exportLogsAsString();
    Clipboard.setData(ClipboardData(text: export));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics logs copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('System Diagnostics',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Logs',
            onPressed: _copyLogsToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rerun Health Check',
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: FormaColors.primaryAccent),
                    SizedBox(height: 16),
                    Text('Running live backend and AI tests...',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              )
            : ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Overview Info Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color:
                          isDark ? FormaColors.charcoal : FormaColors.warmCream,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color:
                              FormaColors.primaryAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: FormaColors.primaryAccent
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.health_and_safety_rounded,
                                  color: FormaColors.goldenYellow, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Live Environment Health',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Genuine connectivity tests for Firebase Authentication, Cloud Firestore, Android Keystore, SQLite, and Gemini 2.0 Flash AI.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? FormaColors.darkSecondaryText
                                : FormaColors.lightSecondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Health Check Cards
                  ..._checks.map((check) => _buildStatusCard(check, isDark)),

                  const SizedBox(height: 16),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FormaButton(
                          label: 'Re-test All',
                          icon: Icons.refresh_rounded,
                          size: FormaButtonSize.small,
                          onPressed: _runDiagnostics,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FormaButton(
                          label: 'Configure Key',
                          icon: Icons.key_rounded,
                          size: FormaButtonSize.small,
                          variant: FormaButtonVariant.secondary,
                          onPressed: () => context.push('/profile/api-key'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Live Event & Error Log Section ("What went wrong")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live Event & Error Log',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'Copy Full Log',
                            onPressed: _copyLogsToClipboard,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            tooltip: 'Clear Log',
                            onPressed: () {
                              AppLogger.clear();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ValueListenableBuilder<int>(
                    valueListenable: AppLogger.logCountNotifier,
                    builder: (context, count, _) {
                      final logs = AppLogger.getLogs();
                      if (logs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? FormaColors.darkCardBackground
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'No recent events or errors recorded.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: FormaColors.concreteGrey),
                            ),
                          ),
                        );
                      }

                      return Container(
                        height: 260,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF141517)
                              : const Color(0xFF222428),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          reverse: true, // Show newest at the bottom
                          itemCount: logs.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white10, height: 10),
                          itemBuilder: (context, index) {
                            final entry = logs[logs.length - 1 - index];
                            Color levelColor;
                            switch (entry.level) {
                              case AppLogLevel.error:
                                levelColor = const Color(0xFFFF6B6B);
                                break;
                              case AppLogLevel.warn:
                                levelColor = const Color(0xFFFFD166);
                                break;
                              case AppLogLevel.success:
                                levelColor = const Color(0xFF06D6A0);
                                break;
                              case AppLogLevel.info:
                                levelColor = const Color(0xFF4CC9F0);
                                break;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      entry.formattedTime,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: Colors.white54,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      entry.levelPrefix,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w800,
                                        color: levelColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '[${entry.tag}]',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.message,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: Colors.white,
                                  ),
                                ),
                                if (entry.errorDetails != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.errorDetails!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      color: Color(0xFFFF8B8B),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusCard(ServiceHealth check, bool isDark) {
    Color badgeColor;
    String badgeText;
    IconData icon;

    switch (check.state) {
      case ServiceCheckState.ready:
        badgeColor = FormaColors.success;
        badgeText = check.metric ?? 'READY';
        icon = Icons.check_circle_rounded;
        break;
      case ServiceCheckState.incomplete:
        badgeColor = FormaColors.goldenYellow;
        badgeText = check.metric ?? 'PENDING';
        icon = Icons.warning_rounded;
        break;
      case ServiceCheckState.failed:
        badgeColor = FormaColors.coralPink;
        badgeText = check.metric ?? 'FAILED';
        icon = Icons.error_rounded;
        break;
      case ServiceCheckState.checking:
        badgeColor = FormaColors.concreteGrey;
        badgeText = 'TESTING';
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: check.state == ServiceCheckState.failed
              ? FormaColors.coralPink.withValues(alpha: 0.4)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: badgeColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? FormaColors.darkPrimaryText
                        : FormaColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  check.details,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? FormaColors.darkSecondaryText
                        : FormaColors.lightSecondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
