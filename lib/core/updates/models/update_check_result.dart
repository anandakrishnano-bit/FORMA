import 'package:flutter/foundation.dart';
import 'package:forma/core/updates/models/app_release_info.dart';

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  criticalUpdateRequired,
  error,
}

@immutable
class UpdateCheckResult {
  final UpdateStatus status;
  final AppReleaseInfo? latestRelease;
  final String currentVersion;
  final int currentVersionCode;
  final DateTime lastChecked;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.status,
    this.latestRelease,
    required this.currentVersion,
    required this.currentVersionCode,
    required this.lastChecked,
    this.errorMessage,
  });

  bool get hasUpdate =>
      status == UpdateStatus.updateAvailable ||
      status == UpdateStatus.criticalUpdateRequired;

  bool get isCritical => status == UpdateStatus.criticalUpdateRequired;

  String? get error => errorMessage;

  factory UpdateCheckResult.upToDate({
    required String currentVersion,
    required int currentVersionCode,
    AppReleaseInfo? latestRelease,
  }) {
    return UpdateCheckResult(
      status: UpdateStatus.upToDate,
      latestRelease: latestRelease,
      currentVersion: currentVersion,
      currentVersionCode: currentVersionCode,
      lastChecked: DateTime.now(),
    );
  }

  factory UpdateCheckResult.available({
    required String currentVersion,
    required int currentVersionCode,
    required AppReleaseInfo latestRelease,
    bool isCritical = false,
  }) {
    return UpdateCheckResult(
      status: isCritical
          ? UpdateStatus.criticalUpdateRequired
          : UpdateStatus.updateAvailable,
      latestRelease: latestRelease,
      currentVersion: currentVersion,
      currentVersionCode: currentVersionCode,
      lastChecked: DateTime.now(),
    );
  }

  factory UpdateCheckResult.error({
    required String currentVersion,
    required int currentVersionCode,
    required String error,
  }) {
    return UpdateCheckResult(
      status: UpdateStatus.error,
      currentVersion: currentVersion,
      currentVersionCode: currentVersionCode,
      lastChecked: DateTime.now(),
      errorMessage: error,
    );
  }

  factory UpdateCheckResult.initial() {
    return UpdateCheckResult(
      status: UpdateStatus.idle,
      currentVersion: '1.0.0',
      currentVersionCode: 1,
      lastChecked: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
