import 'package:flutter/foundation.dart';

/// Update urgency priority level.
enum UpdatePriority {
  /// Standard improvements or bug fixes. User can dismiss or update anytime.
  normal,

  /// Recommended update with major performance or feature enhancements.
  important,

  /// Required update due to critical security, schema migration, or backend incompatibility.
  critical;

  static UpdatePriority fromString(String? value) {
    if (value == null) return UpdatePriority.normal;
    switch (value.trim().toLowerCase()) {
      case 'critical':
      case 'mandatory':
      case 'required':
        return UpdatePriority.critical;
      case 'important':
      case 'recommended':
      case 'high':
        return UpdatePriority.important;
      default:
        return UpdatePriority.normal;
    }
  }

  String get displayName {
    switch (this) {
      case UpdatePriority.normal:
        return 'Standard Update';
      case UpdatePriority.important:
        return 'Important Update';
      case UpdatePriority.critical:
        return 'Critical Update';
    }
  }
}

/// Parsed release metadata retrieved from GitHub Releases.
@immutable
class AppReleaseInfo {
  final String version; // e.g. "1.1.0"
  final int versionCode; // e.g. 2
  final String title;
  final String releaseNotes;
  final DateTime publishedAt;
  final bool isPrerelease;
  final bool isDraft;
  final UpdatePriority priority;
  final String? minSupportedVersion;
  final String apkDownloadUrl;
  final String apkFileName;
  final int apkSizeBytes;
  final String? sha256Checksum;
  final String htmlUrl;

  String get tagName => 'v$version';

  const AppReleaseInfo({
    required this.version,
    required this.versionCode,
    required this.title,
    required this.releaseNotes,
    required this.publishedAt,
    this.isPrerelease = false,
    this.isDraft = false,
    this.priority = UpdatePriority.normal,
    this.minSupportedVersion,
    required this.apkDownloadUrl,
    required this.apkFileName,
    required this.apkSizeBytes,
    this.sha256Checksum,
    required this.htmlUrl,
  });

  /// Factory that parses a GitHub Release API JSON map and attached assets.
  factory AppReleaseInfo.fromGitHubRelease(
    Map<String, dynamic> json, {
    Map<String, dynamic>? metadataJson,
    String? checksumText,
  }) {
    final rawTag = (json['tag_name'] as String?) ?? '';
    final cleanVersion = _cleanVersionString(rawTag.isNotEmpty ? rawTag : (json['name'] as String? ?? '1.0.0'));

    final assets = (json['assets'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? apkAsset;

    // Search for suitable Android APK asset
    for (final a in assets) {
      if (a is Map<String, dynamic>) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkAsset = a;
          break;
        }
      }
    }

    if (apkAsset == null) {
      throw const FormatException('Release does not contain an Android .apk asset.');
    }

    final downloadUrl = (apkAsset['browser_download_url'] as String?) ?? '';
    final fileName = (apkAsset['name'] as String?) ?? 'forma-release.apk';
    final sizeBytes = (apkAsset['size'] as num?)?.toInt() ?? 0;

    // Determine versionCode
    int parsedCode = 1;
    if (metadataJson != null && metadataJson['versionCode'] != null) {
      parsedCode = (metadataJson['versionCode'] as num).toInt();
    } else {
      // Attempt extraction from version string e.g. 1.2.0+5
      if (rawTag.contains('+')) {
        parsedCode = int.tryParse(rawTag.split('+').last) ?? 1;
      }
    }

    // Determine priority
    UpdatePriority parsedPriority = UpdatePriority.normal;
    if (metadataJson != null && metadataJson['priority'] != null) {
      parsedPriority = UpdatePriority.fromString(metadataJson['priority']?.toString());
    } else {
      final bodyText = (json['body'] as String?) ?? '';
      if (bodyText.contains('[priority:critical]') || bodyText.contains('#priority:critical')) {
        parsedPriority = UpdatePriority.critical;
      } else if (bodyText.contains('[priority:important]') || bodyText.contains('#priority:important')) {
        parsedPriority = UpdatePriority.important;
      }
    }

    // Extract Checksum if present
    String? expectedSha256;
    if (metadataJson != null && metadataJson['sha256'] != null) {
      expectedSha256 = (metadataJson['sha256'] as String).trim().toLowerCase();
    } else if (checksumText != null && checksumText.isNotEmpty) {
      expectedSha256 = _extractChecksumFromText(checksumText, fileName);
    }

    return AppReleaseInfo(
      version: cleanVersion,
      versionCode: parsedCode,
      title: (json['name'] as String?) ?? cleanVersion,
      releaseNotes: (json['body'] as String?) ?? 'Performance optimizations and general stability improvements.',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? '') ?? DateTime.now(),
      isPrerelease: (json['prerelease'] as bool?) ?? false,
      isDraft: (json['draft'] as bool?) ?? false,
      priority: parsedPriority,
      minSupportedVersion: metadataJson?['minSupportedVersion'] as String?,
      apkDownloadUrl: downloadUrl,
      apkFileName: fileName,
      apkSizeBytes: sizeBytes,
      sha256Checksum: expectedSha256,
      htmlUrl: (json['html_url'] as String?) ?? 'https://github.com/anandakrishnano-bit/FORMA/releases',
    );
  }

  /// Compares this release version against the installed app version.
  /// Returns `true` if this release is strictly newer.
  bool isNewerThan(String installedVersionName, int installedVersionCode) {
    // 1. Try comparing versionCodes if both are strictly meaningful
    if (versionCode > installedVersionCode) {
      return true;
    }

    // 2. Fallback to semantic version comparison
    final releaseParts = _parseSemantic(version);
    final installedParts = _parseSemantic(_cleanVersionString(installedVersionName));

    for (int i = 0; i < 3; i++) {
      if (releaseParts[i] > installedParts[i]) return true;
      if (releaseParts[i] < installedParts[i]) return false;
    }

    // If semantic numbers are equal, check versionCode
    return versionCode > installedVersionCode;
  }

  /// Determines whether the installed version is older than the required minimum.
  bool isCriticalFor(String installedVersionName, int installedVersionCode) {
    if (priority == UpdatePriority.critical) return true;
    if (minSupportedVersion == null || minSupportedVersion!.isEmpty) return false;

    final minParts = _parseSemantic(_cleanVersionString(minSupportedVersion!));
    final installedParts = _parseSemantic(_cleanVersionString(installedVersionName));

    for (int i = 0; i < 3; i++) {
      if (installedParts[i] < minParts[i]) return true;
      if (installedParts[i] > minParts[i]) return false;
    }
    return false;
  }

  static String _cleanVersionString(String input) {
    var v = input.trim();
    if (v.toLowerCase().startsWith('v')) {
      v = v.substring(1);
    }
    if (v.contains('+')) {
      v = v.split('+').first;
    }
    return v.trim();
  }

  static List<int> _parseSemantic(String v) {
    final clean = _cleanVersionString(v);
    final parts = clean.split('.');
    final major = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final patch = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    return [major, minor, patch];
  }

  static String? _extractChecksumFromText(String text, String targetFileName) {
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Match patterns like "a1b2c3... filename.apk" or "SHA256(filename.apk)= a1b2c3..."
      if (trimmed.contains(targetFileName)) {
        final tokens = trimmed.split(RegExp(r'\s+'));
        for (final token in tokens) {
          final clean = token.replaceAll(RegExp(r'[^a-fA-F0-9]'), '').toLowerCase();
          if (clean.length == 64) {
            return clean;
          }
        }
      }
    }
    // If text is purely a 64-char hash
    final direct = text.trim().toLowerCase();
    if (direct.length == 64 && RegExp(r'^[a-f0-9]{64}$').hasMatch(direct)) {
      return direct;
    }
    return null;
  }
}
