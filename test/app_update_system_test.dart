import 'package:flutter_test/flutter_test.dart';
import 'package:forma/core/updates/models/app_release_info.dart';
import 'package:forma/core/updates/models/download_progress.dart';
import 'package:forma/core/updates/models/update_check_result.dart';

void main() {
  group('AppReleaseInfo & Semantic Versioning Tests', () {
    test('Correctly parses GitHub Release payload with APK asset', () {
      final mockReleaseJson = {
        'tag_name': 'v1.2.0',
        'name': 'FORMA v1.2.0 - Core Upgrades',
        'body': '### Features\n- Background sync\n- Performance improvements',
        'published_at': '2026-11-15T12:00:00Z',
        'draft': false,
        'prerelease': false,
        'html_url':
            'https://github.com/anandakrishnano-bit/FORMA/releases/tag/v1.2.0',
        'assets': [
          {
            'name': 'forma-v1.2.0.apk',
            'browser_download_url':
                'https://github.com/anandakrishnano-bit/FORMA/releases/download/v1.2.0/forma-v1.2.0.apk',
            'size': 45678901,
          },
        ],
      };

      final release = AppReleaseInfo.fromGitHubRelease(mockReleaseJson);

      expect(release.version, '1.2.0');
      expect(release.tagName, 'v1.2.0');
      expect(release.title, 'FORMA v1.2.0 - Core Upgrades');
      expect(release.apkFileName, 'forma-v1.2.0.apk');
      expect(release.apkSizeBytes, 45678901);
      expect(release.priority, UpdatePriority.normal);
      expect(release.isDraft, false);
      expect(release.isPrerelease, false);
    });

    test('Parses metadata and checksum companion files when present', () {
      final mockReleaseJson = {
        'tag_name': 'v2.0.0',
        'name': 'FORMA v2.0.0 Major',
        'body': 'Major upgrade',
        'published_at': '2026-11-15T12:00:00Z',
        'assets': [
          {
            'name': 'forma-v2.0.0.apk',
            'browser_download_url': 'https://example.com/app.apk',
            'size': 50000000,
          },
        ],
      };

      final mockMetadata = {
        'version': '2.0.0',
        'versionCode': 10,
        'priority': 'critical',
        'minSupportedVersion': '1.5.0',
      };

      final mockChecksumText =
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 forma-v2.0.0.apk';

      final release = AppReleaseInfo.fromGitHubRelease(
        mockReleaseJson,
        metadataJson: mockMetadata,
        checksumText: mockChecksumText,
      );

      expect(release.versionCode, 10);
      expect(release.priority, UpdatePriority.critical);
      expect(release.minSupportedVersion, '1.5.0');
      expect(release.sha256Checksum,
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    });

    test('Semantic version comparisons work accurately', () {
      final release = AppReleaseInfo(
        version: '1.2.0',
        versionCode: 5,
        title: 'Update',
        releaseNotes: 'Notes',
        publishedAt: DateTime.now(),
        apkDownloadUrl: 'https://example.com/app.apk',
        apkFileName: 'app.apk',
        apkSizeBytes: 1000,
        priority: UpdatePriority.normal,
        htmlUrl: 'https://example.com',
      );

      // Current is older -> true
      expect(release.isNewerThan('1.1.9', 4), isTrue);
      expect(release.isNewerThan('1.0.0', 1), isTrue);
      expect(release.isNewerThan('1.2.0', 4), isTrue); // Higher build code

      // Current is same or newer -> false
      expect(release.isNewerThan('1.2.0', 5), isFalse);
      expect(release.isNewerThan('1.2.1', 6), isFalse);
      expect(release.isNewerThan('2.0.0', 10), isFalse);
    });

    test('Critical update enforcement works accurately', () {
      final criticalRelease = AppReleaseInfo(
        version: '2.0.0',
        versionCode: 15,
        title: 'Major Security Patch',
        releaseNotes: 'Breaking changes',
        publishedAt: DateTime.now(),
        apkDownloadUrl: 'https://example.com/app.apk',
        apkFileName: 'app.apk',
        apkSizeBytes: 1000,
        priority: UpdatePriority.critical,
        minSupportedVersion: '1.9.0',
        htmlUrl: 'https://example.com',
      );

      // Below minSupportedVersion -> critical
      expect(criticalRelease.isCriticalFor('1.8.5', 10), isTrue);

      // Has priority critical -> critical
      expect(criticalRelease.isCriticalFor('1.9.5', 14), isTrue);

      final normalRelease = AppReleaseInfo(
        version: '2.0.0',
        versionCode: 15,
        title: 'Patch',
        releaseNotes: 'Notes',
        publishedAt: DateTime.now(),
        apkDownloadUrl: 'https://example.com/app.apk',
        apkFileName: 'app.apk',
        apkSizeBytes: 1000,
        priority: UpdatePriority.normal,
        minSupportedVersion: '1.9.0',
        htmlUrl: 'https://example.com',
      );

      // Supported version and normal priority -> not critical
      expect(normalRelease.isCriticalFor('1.9.5', 14), isFalse);
    });
  });

  group('DownloadProgress formatting and state tests', () {
    test('Byte formatting displays clean units', () {
      expect(DownloadProgress.formatBytes(500), '500.0 B');
      expect(DownloadProgress.formatBytes(1024), '1.0 KB');
      expect(DownloadProgress.formatBytes(1024 * 1024 * 48), '48.0 MB');
      expect(DownloadProgress.formatBytes(1024 * 1024 * 1024 * 2), '2.0 GB');
    });

    test('Progress percentage and speed formatting', () {
      final progress = DownloadProgress.downloading(
        received: 25000000,
        total: 50000000,
        speed: 2500000,
      );

      expect(progress.isDownloading, isTrue);
      expect(progress.progress, closeTo(0.5, 0.01));
      expect(progress.formattedSpeed, '2.4 MB/s');
    });

    test('UpdateCheckResult states', () {
      final initial = UpdateCheckResult.initial();
      expect(initial.status, UpdateStatus.idle);
      expect(initial.hasUpdate, isFalse);

      final upToDate = UpdateCheckResult.upToDate(
        currentVersion: '1.0.0',
        currentVersionCode: 1,
      );
      expect(upToDate.status, UpdateStatus.upToDate);
      expect(upToDate.hasUpdate, isFalse);
    });
  });
}
