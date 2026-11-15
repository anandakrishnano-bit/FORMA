import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:forma/core/updates/models/app_release_info.dart';

/// Service responsible for querying GitHub Releases API to discover published FORMA updates.
class GitHubReleaseService {
  final http.Client _client;

  // Central GitHub Repository Configuration
  static const String repositoryOwner = 'anandakrishnano-bit';
  static const String repositoryName = 'FORMA';
  static const String _apiBaseUrl =
      'https://api.github.com/repos/$repositoryOwner/$repositoryName';

  GitHubReleaseService({http.Client? client})
      : _client = client ?? http.Client();

  /// Fetches the latest published stable release from GitHub Releases.
  /// Ignores draft releases and prereleases.
  Future<AppReleaseInfo?> fetchLatestRelease() async {
    final uri = Uri.parse('$_apiBaseUrl/releases');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'FORMA-Android-App/1.0',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final List<dynamic> releasesList =
            jsonDecode(response.body) as List<dynamic>;
        if (releasesList.isEmpty) return null;

        // Iterate to find the newest non-draft, non-prerelease containing an APK asset
        for (final item in releasesList) {
          if (item is! Map<String, dynamic>) continue;
          final isDraft = (item['draft'] as bool?) ?? false;
          final isPrerelease = (item['prerelease'] as bool?) ?? false;

          if (isDraft || isPrerelease) continue;

          // Check if it has an APK asset
          final assets = (item['assets'] as List<dynamic>?) ?? [];
          final hasApk = assets.any((a) =>
              a is Map<String, dynamic> &&
              (a['name'] as String? ?? '').toLowerCase().endsWith('.apk'));

          if (!hasApk) continue;

          // Attempt to load companion metadata and checksum assets if published
          Map<String, dynamic>? metadataJson;
          String? checksumText;

          for (final a in assets) {
            if (a is! Map<String, dynamic>) continue;
            final name = (a['name'] as String? ?? '').toLowerCase();
            final downloadUrl = (a['browser_download_url'] as String?) ?? '';

            if (name == 'release-metadata.json' && downloadUrl.isNotEmpty) {
              metadataJson = await _fetchJsonAsset(downloadUrl);
            } else if ((name.contains('sha256') || name.contains('checksum')) &&
                downloadUrl.isNotEmpty) {
              checksumText = await _fetchTextAsset(downloadUrl);
            }
          }

          try {
            return AppReleaseInfo.fromGitHubRelease(
              item,
              metadataJson: metadataJson,
              checksumText: checksumText,
            );
          } catch (_) {
            // Malformed release; skip to next candidate
            continue;
          }
        }
        return null;
      } else if (response.statusCode == 403 || response.statusCode == 429) {
        throw const FormatException(
            'GitHub update service is currently rate limited. Please try again later.');
      } else if (response.statusCode == 404) {
        return null; // No releases published yet
      } else {
        throw FormatException(
            'Update check failed with server status ${response.statusCode}.');
      }
    } on http.ClientException {
      throw const FormatException(
          'Network connection error while checking for updates.');
    }
  }

  Future<Map<String, dynamic>?> _fetchJsonAsset(String url) async {
    try {
      final res =
          await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchTextAsset(String url) async {
    try {
      final res =
          await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return res.body;
      }
    } catch (_) {}
    return null;
  }
}
