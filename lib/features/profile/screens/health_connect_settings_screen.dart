import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/components/forma_button.dart';
import 'package:forma/core/services/health_connect_service.dart';

/// Health Connect Data & Permission Management Screen.
///
/// Route: /health-connect-settings
class HealthConnectSettingsScreen extends ConsumerStatefulWidget {
  const HealthConnectSettingsScreen({super.key});

  @override
  ConsumerState<HealthConnectSettingsScreen> createState() =>
      _HealthConnectSettingsScreenState();
}

class _HealthConnectSettingsScreenState
    extends ConsumerState<HealthConnectSettingsScreen> {
  bool _isLoading = false;

  Future<void> _toggleConnection() async {
    setState(() => _isLoading = true);
    final isConnected = await HealthConnectService().isEnabled();

    if (isConnected) {
      await HealthConnectService().disconnect();
      ref.invalidate(healthConnectStatusProvider);
      ref.invalidate(healthConnectMetricsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Health Connect disconnected from FORMA.'),
            backgroundColor: FormaColors.charcoal,
          ),
        );
      }
    } else {
      final granted = await HealthConnectService().requestPermissions();
      ref.invalidate(healthConnectStatusProvider);
      ref.invalidate(healthConnectMetricsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? '✓ Google Health Connect connected successfully!'
                  : 'Health Connect permissions were not granted or cancelled.',
            ),
            backgroundColor:
                granted ? FormaColors.success : FormaColors.coralPink,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusAsync = ref.watch(healthConnectStatusProvider);
    final isConnected = statusAsync.valueOrNull ?? false;

    return Scaffold(
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      appBar: AppBar(
        title: const Text('Google Health Connect',
            style: TextStyle(fontWeight: FontWeight.w800)),
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status Hero
              Container(
                padding: const EdgeInsets.all(22),
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
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected
                                ? FormaColors.success.withValues(alpha: 0.18)
                                : FormaColors.concreteGrey
                                    .withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            isConnected
                                ? Icons.health_and_safety_rounded
                                : Icons.link_off_rounded,
                            color: isConnected
                                ? FormaColors.success
                                : FormaColors.concreteGrey,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnected
                                    ? 'Health Connect Active'
                                    : 'Not Connected',
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isConnected
                                    ? 'Daily steps, calories and vitals synced securely'
                                    : 'Connect to sync steps, active calories & vitals',
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
                    const SizedBox(height: 20),
                    FormaButton(
                      label: isConnected
                          ? 'Disconnect Health Connect'
                          : 'Connect Health Connect',
                      variant: isConnected
                          ? FormaButtonVariant.secondary
                          : FormaButtonVariant.primary,
                      icon: isConnected
                          ? Icons.link_off_rounded
                          : Icons.link_rounded,
                      isLoading: _isLoading,
                      onPressed: _toggleConnection,
                    ),
                    if (isConnected) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() => _isLoading = true);
                                ref.invalidate(healthConnectMetricsProvider);
                                await HealthConnectService()
                                    .fetchDailyMetrics(DateTime.now());
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          '✓ Health Connect metrics synced successfully!'),
                                      backgroundColor: FormaColors.success,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Sync Now',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Supported Metrics List
              const Text(
                'SUPPORTED DATA TYPES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: FormaColors.concreteGrey,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.darkCardBackground
                      : FormaColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildMetricTile(
                      icon: Icons.directions_walk_rounded,
                      color: FormaColors.azure,
                      title: 'Steps & Daily Movement',
                      subtitle:
                          'Used for daily energy rings and movement tracking',
                      isActive: isConnected,
                    ),
                    const Divider(height: 1),
                    _buildMetricTile(
                      icon: Icons.local_fire_department_rounded,
                      color: FormaColors.goldenYellow,
                      title: 'Active & Total Calories Burned',
                      subtitle: 'Used for calorie balance (spend vs consumed)',
                      isActive: isConnected,
                    ),
                    const Divider(height: 1),
                    _buildMetricTile(
                      icon: Icons.favorite_rounded,
                      color: FormaColors.coralPink,
                      title: 'Heart Rate',
                      subtitle: 'Latest and resting heart-rate readings',
                      isActive: isConnected,
                    ),
                    const Divider(height: 1),
                    _buildMetricTile(
                      icon: Icons.straighten_rounded,
                      color: FormaColors.sage,
                      title: 'Distance Travelled',
                      subtitle: 'Daily walking and running distance in km',
                      isActive: isConnected,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Privacy Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.charcoal : FormaColors.warmCream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: FormaColors.concreteGrey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: FormaColors.sage, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your health data is 100% private. It remains on your device and is never shared with friends or uploaded without your explicit permission.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark
                              ? FormaColors.darkSecondaryText
                              : FormaColors.lightSecondaryText,
                        ),
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

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isActive ? FormaColors.success : FormaColors.concreteGrey)
              .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isActive ? 'Active' : 'Off',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? FormaColors.success : FormaColors.concreteGrey,
          ),
        ),
      ),
    );
  }
}
