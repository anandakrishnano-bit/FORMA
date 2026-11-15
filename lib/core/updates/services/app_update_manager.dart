import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma/core/updates/models/app_release_info.dart';
import 'package:forma/core/updates/models/download_progress.dart';
import 'package:forma/core/updates/models/update_check_result.dart';
import 'package:forma/core/updates/services/apk_download_service.dart';
import 'package:forma/core/updates/services/app_update_platform_service.dart';
import 'package:forma/core/updates/services/github_release_service.dart';

final appUpdatePlatformServiceProvider = Provider<AppUpdatePlatformService>((ref) {
  return AppUpdatePlatformService();
});

final gitHubReleaseServiceProvider = Provider<GitHubReleaseService>((ref) {
  return GitHubReleaseService();
});

final apkDownloadServiceProvider = Provider<ApkDownloadService>((ref) {
  return ApkDownloadService();
});

final updateCheckStateProvider = StateNotifierProvider<UpdateCheckNotifier, UpdateCheckResult>((ref) {
  return UpdateCheckNotifier(ref);
});

final downloadProgressStateProvider = StateNotifierProvider<DownloadProgressNotifier, DownloadProgress>((ref) {
  return DownloadProgressNotifier(ref.watch(apkDownloadServiceProvider));
});

class UpdateCheckNotifier extends StateNotifier<UpdateCheckResult> {
  final Ref _ref;
  static const String _keyLastChecked = 'forma_last_update_check_timestamp';
  static const String _keyDismissedVersion = 'forma_dismissed_update_version';
  static const Duration _autoCheckInterval = Duration(hours: 4);

  UpdateCheckNotifier(this._ref) : super(UpdateCheckResult.initial()) {
    _loadInitialVersion();
  }

  Future<void> _loadInitialVersion() async {
    final platform = _ref.read(appUpdatePlatformServiceProvider);
    final info = await platform.getInstalledVersionInfo();
    state = UpdateCheckResult.upToDate(
      currentVersion: info.versionName,
      currentVersionCode: info.versionCode,
    );
  }

  /// Checks for updates. If [force] is true, ignores caching and makes a live network call.
  Future<UpdateCheckResult> checkForUpdates({bool force = false}) async {
    final platform = _ref.read(appUpdatePlatformServiceProvider);
    final github = _ref.read(gitHubReleaseServiceProvider);
    final prefs = await SharedPreferences.getInstance();

    final info = await platform.getInstalledVersionInfo();
    final currentVersion = info.versionName;
    final currentCode = info.versionCode;

    // Check throttling for automatic checks
    if (!force) {
      final lastCheckedMs = prefs.getInt(_keyLastChecked) ?? 0;
      final lastChecked = DateTime.fromMillisecondsSinceEpoch(lastCheckedMs);
      if (DateTime.now().difference(lastChecked) < _autoCheckInterval) {
        // Return existing state if already checked recently
        if (state.status != UpdateStatus.idle) {
          return state;
        }
      }
    }

    state = UpdateCheckResult(
      status: UpdateStatus.checking,
      currentVersion: currentVersion,
      currentVersionCode: currentCode,
      lastChecked: DateTime.now(),
    );

    try {
      final latest = await github.fetchLatestRelease();
      await prefs.setInt(_keyLastChecked, DateTime.now().millisecondsSinceEpoch);

      if (latest == null) {
        final result = UpdateCheckResult.upToDate(
          currentVersion: currentVersion,
          currentVersionCode: currentCode,
        );
        state = result;
        return result;
      }

      final isNewer = latest.isNewerThan(currentVersion, currentCode);
      if (isNewer) {
        final isCritical = latest.isCriticalFor(currentVersion, currentCode);
        final result = UpdateCheckResult.available(
          currentVersion: currentVersion,
          currentVersionCode: currentCode,
          latestRelease: latest,
          isCritical: isCritical,
        );
        state = result;
        return result;
      } else {
        final result = UpdateCheckResult.upToDate(
          currentVersion: currentVersion,
          currentVersionCode: currentCode,
          latestRelease: latest,
        );
        state = result;
        return result;
      }
    } catch (e) {
      final result = UpdateCheckResult.error(
        currentVersion: currentVersion,
        currentVersionCode: currentCode,
        error: e.toString().replaceAll('Exception: ', '').replaceAll('FormatException: ', ''),
      );
      state = result;
      return result;
    }
  }

  /// Checks if a non-critical version was previously dismissed by the user.
  Future<bool> isVersionDismissed(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getString(_keyDismissedVersion);
    return dismissed == version;
  }

  /// Marks a version as dismissed for the session.
  Future<void> dismissVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDismissedVersion, version);
  }
}

class DownloadProgressNotifier extends StateNotifier<DownloadProgress> {
  final ApkDownloadService _downloadService;
  StreamSubscription<DownloadProgress>? _subscription;

  DownloadProgressNotifier(this._downloadService) : super(DownloadProgress.idle());

  void startDownload(AppReleaseInfo release) {
    _subscription?.cancel();
    state = DownloadProgress.downloading(received: 0, total: release.apkSizeBytes, speed: 0);

    _subscription = _downloadService.downloadApk(release).listen(
      (progress) {
        state = progress;
      },
      onError: (e) {
        state = DownloadProgress.failed(e.toString());
      },
      onDone: () {
        _subscription = null;
      },
    );
  }

  void cancelDownload() {
    _subscription?.cancel();
    _subscription = null;
    _downloadService.cancelDownload();
    state = DownloadProgress.cancelled();
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    state = DownloadProgress.idle();
  }
}
