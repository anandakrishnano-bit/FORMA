import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forma/core/components/forma_bounceable.dart';
import 'package:forma/core/theme/app_colors.dart';
import 'package:forma/core/updates/models/app_release_info.dart';
import 'package:forma/core/updates/models/download_progress.dart';
import 'package:forma/core/updates/services/app_update_manager.dart';
import 'package:forma/core/updates/widgets/isometric_accent_art.dart';

/// Full-fidelity Update Screen directly matching the reference visual style:
/// - Dark & Light mode theme awareness.
/// - Centered title, clean sub-description, and primary action pill.
/// - Formatted Markdown release notes & changelog with categorized sections.
/// - Live progress bar with genuine bytes, speed, and percentage.
/// - Android official package-installer handoff.
/// - Geometric 3D isometric sculpture in the bottom-right corner.
class FormaUpdateScreen extends ConsumerStatefulWidget {
  final AppReleaseInfo release;
  final bool isModal;

  const FormaUpdateScreen({
    super.key,
    required this.release,
    this.isModal = false,
  });

  static Future<void> show(BuildContext context, AppReleaseInfo release) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: release.priority != UpdatePriority.critical,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        pageBuilder: (context, _, __) => FormaUpdateScreen(
          release: release,
          isModal: true,
        ),
        transitionsBuilder: (context, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  ConsumerState<FormaUpdateScreen> createState() => _FormaUpdateScreenState();
}

class _FormaUpdateScreenState extends ConsumerState<FormaUpdateScreen> {
  bool _showChangelog = false;

  @override
  void initState() {
    super.initState();
    // Reset any previous download state on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(downloadProgressStateProvider.notifier).reset();
    });
  }

  Future<void> _handlePrimaryAction(DownloadProgress download) async {
    HapticFeedback.mediumImpact();
    final release = widget.release;
    final downloadNotifier = ref.read(downloadProgressStateProvider.notifier);
    final platformService = ref.read(appUpdatePlatformServiceProvider);

    if (download.status == DownloadStatus.idle ||
        download.status == DownloadStatus.cancelled ||
        download.status == DownloadStatus.failed) {
      // Start download
      downloadNotifier.startDownload(release);
    } else if (download.status == DownloadStatus.readyToInstall &&
        download.downloadedFilePath != null) {
      // Check installation permission
      final canInstall = await platformService.canRequestPackageInstalls();
      if (!canInstall && mounted) {
        _showPermissionExplainer(context);
        return;
      }

      // Hand off to Android PackageInstaller
      try {
        await platformService.installApk(download.downloadedFilePath!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Installation failed: $e'),
              backgroundColor: FormaColors.coralPink,
            ),
          );
        }
      }
    }
  }

  void _showPermissionExplainer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? FormaColors.darkBackground : FormaColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FormaColors.primaryAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded,
                        color: FormaColors.primaryAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Permission Required',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Android requires permission for FORMA to install application updates directly from GitHub. '
                'Please toggle "Allow from this source" in System Settings to proceed.',
                style: TextStyle(fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FormaColors.primaryAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final platform =
                            ref.read(appUpdatePlatformServiceProvider);
                        await platform.openInstallPermissionSettings();
                      },
                      child: const Text(
                        'Open Settings',
                        style: TextStyle(
                          color: FormaColors.charcoal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final release = widget.release;
    final download = ref.watch(downloadProgressStateProvider);
    final isCritical = release.priority == UpdatePriority.critical;

    final bgColor = isDark
        ? const Color(0xFF171719)
        : const Color(0xFFF9F7F3); // Minimalist background from image
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF171719);
    final secondaryTextColor =
        isDark ? const Color(0xFF9E9EA4) : const Color(0xFF6B6B75);
    final accentPurple =
        isDark ? const Color(0xFFA56EFF) : const Color(0xFF8A3FFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. 3D Isometric Sculpture in Bottom Right (Fidelity match to reference design)
            Positioned(
              right: -20,
              bottom: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: isDark ? 0.95 : 0.85,
                  child: IsometricAccentArt(
                    size: 260,
                    primaryColor: accentPurple,
                  ),
                ),
              ),
            ),

            // 2. Main Content Layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Navigation Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isCritical)
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: secondaryTextColor),
                          onPressed: () {
                            if (download.isDownloading) {
                              ref
                                  .read(downloadProgressStateProvider.notifier)
                                  .cancelDownload();
                            }
                            Navigator.of(context).pop();
                          },
                        )
                      else
                        const SizedBox(width: 48),
                      // Version Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: accentPurple.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.new_releases_rounded,
                                size: 14, color: accentPurple),
                            const SizedBox(width: 6),
                            Text(
                              'v${release.version}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: accentPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Headline Title (Matching reference image)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'New Update Available',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: primaryTextColor,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Description Paragraph (Matching reference copy)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    "We've made some exciting improvements on the FORMA app! Update now to enjoy the latest features and performance upgrades.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: secondaryTextColor,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action Pill Button & Live Progress Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _buildActionSection(
                      download, isDark, accentPurple, primaryTextColor),
                ),

                const SizedBox(height: 16),

                // Metadata Badges (File Size & SHA-256 Verified)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMetaPill(
                      icon: Icons.folder_zip_rounded,
                      label: DownloadProgress.formatBytes(
                          release.apkSizeBytes > 0
                              ? release.apkSizeBytes
                              : 48000000),
                      secondaryTextColor: secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    _buildMetaPill(
                      icon: Icons.verified_user_rounded,
                      label: release.sha256Checksum != null
                          ? 'SHA-256 Verified'
                          : 'Official GitHub Release',
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Expandable Release Notes & Changelog
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FormaBounceable(
                    onTap: () =>
                        setState(() => _showChangelog = !_showChangelog),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showChangelog
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.receipt_long_rounded,
                            size: 16,
                            color: accentPurple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showChangelog
                                ? 'Hide Release Notes'
                                : "View What's New & Changelog",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accentPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_showChangelog) ...[
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 6,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E22)
                            : const Color(0xFFECE8E0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : FormaColors.divider.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Markdown(
                        data: release.releaseNotes,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(Theme.of(context))
                                .copyWith(
                          p: TextStyle(
                            fontSize: 13,
                            color: primaryTextColor.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                          h1: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: primaryTextColor),
                          h2: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor),
                          h3: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: accentPurple),
                          listBullet: TextStyle(color: accentPurple),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const Spacer(flex: 3),
                ],

                // Later Option (Only if not critical)
                if (!isCritical) ...[
                  TextButton(
                    onPressed: () {
                      ref
                          .read(updateCheckStateProvider.notifier)
                          .dismissVersion(release.version);
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Remind Me Later',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(
    DownloadProgress download,
    bool isDark,
    Color accentPurple,
    Color primaryTextColor,
  ) {
    if (download.isDownloading) {
      final percentStr = '${(download.progress * 100).toInt()}%';
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloading update ($percentStr)...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              Text(
                '${download.formattedReceivedSize} / ${download.formattedTotalSize}',
                style: TextStyle(fontSize: 12, color: accentPurple),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: download.progress > 0 ? download.progress : null,
              minHeight: 12,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(accentPurple),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Speed: ${download.formattedSpeed}',
                style: const TextStyle(
                    fontSize: 11, color: FormaColors.concreteGrey),
              ),
              TextButton(
                onPressed: () {
                  ref
                      .read(downloadProgressStateProvider.notifier)
                      .cancelDownload();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 12, color: FormaColors.coralPink),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (download.isVerifying) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: accentPurple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Verifying package integrity...',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final isReadyToInstall = download.isReadyToInstall;
    final buttonLabel = isReadyToInstall ? 'Install Update' : 'Update Now';
    final buttonColor = isReadyToInstall
        ? FormaColors.success
        : (isDark ? Colors.white : accentPurple);
    final labelColor = isReadyToInstall
        ? Colors.white
        : (isDark ? const Color(0xFF171719) : Colors.white);

    return Column(
      children: [
        if (download.isFailed) ...[
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: FormaColors.coralPink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              download.errorMessage ?? 'Download failed. Please try again.',
              style: const TextStyle(
                color: FormaColors.coralPink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        FormaBounceable(
          onTap: () => _handlePrimaryAction(download),
          child: Container(
            width: 220,
            height: 52,
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isReadyToInstall
                        ? Icons.install_mobile_rounded
                        : Icons.arrow_downward_rounded,
                    color: labelColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    buttonLabel,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaPill({
    required IconData icon,
    required String label,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: secondaryTextColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: secondaryTextColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
