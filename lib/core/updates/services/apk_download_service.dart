import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:forma/core/updates/models/app_release_info.dart';
import 'package:forma/core/updates/models/download_progress.dart';

/// Service responsible for streaming APK downloads with genuine progress tracking,
/// SHA-256 verification, and cancellation.
class ApkDownloadService {
  final http.Client _client;
  StreamSubscription<List<int>>? _currentSubscription;
  IOSink? _currentFileSink;
  File? _currentTempFile;
  bool _isCancelled = false;

  ApkDownloadService({http.Client? client}) : _client = client ?? http.Client();

  /// Downloads an APK from the official release asset and reports live progress.
  Stream<DownloadProgress> downloadApk(AppReleaseInfo release) async* {
    _isCancelled = false;
    yield DownloadProgress.downloading(received: 0, total: release.apkSizeBytes, speed: 0);

    final request = http.Request('GET', Uri.parse(release.apkDownloadUrl));
    request.headers['User-Agent'] = 'FORMA-Android-App/1.0';

    http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e) {
      yield DownloadProgress.failed('Failed to connect to update server: $e');
      return;
    }

    if (response.statusCode != 200) {
      yield DownloadProgress.failed('Download failed with HTTP status ${response.statusCode}');
      return;
    }

    final totalBytes = response.contentLength ?? release.apkSizeBytes;

    // Prepare target directory in app's cache
    final tempDir = await getTemporaryDirectory();
    final updateDir = Directory('${tempDir.path}/updates');
    if (!await updateDir.exists()) {
      await updateDir.create(recursive: true);
    }

    // Clean up any stale APKs
    try {
      final oldFiles = updateDir.listSync();
      for (final f in oldFiles) {
        if (f is File && f.path.endsWith('.apk')) {
          f.deleteSync();
        }
      }
    } catch (_) {}

    final safeFileName = 'forma-v${release.version}-${release.versionCode}.apk';
    final targetFile = File('${updateDir.path}/$safeFileName');
    _currentTempFile = targetFile;

    final sink = targetFile.openWrite();
    _currentFileSink = sink;

    int receivedBytes = 0;
    int lastReceivedSnapshot = 0;
    var lastTimeSnapshot = DateTime.now();
    double currentSpeed = 0.0;

    final controller = StreamController<DownloadProgress>();

    _currentSubscription = response.stream.listen(
      (chunk) {
        if (_isCancelled) return;
        sink.add(chunk);
        receivedBytes += chunk.length;

        final now = DateTime.now();
        final elapsedMs = now.difference(lastTimeSnapshot).inMilliseconds;

        if (elapsedMs >= 400 || receivedBytes == totalBytes) {
          final bytesDiff = receivedBytes - lastReceivedSnapshot;
          if (elapsedMs > 0) {
            currentSpeed = (bytesDiff / (elapsedMs / 1000.0));
          }
          lastReceivedSnapshot = receivedBytes;
          lastTimeSnapshot = now;

          controller.add(
            DownloadProgress.downloading(
              received: receivedBytes,
              total: totalBytes,
              speed: currentSpeed,
            ),
          );
        }
      },
      onError: (e) {
        controller.add(DownloadProgress.failed('Download interrupted: $e'));
      },
      onDone: () async {
        await sink.flush();
        await sink.close();
        _currentFileSink = null;

        if (_isCancelled) {
          controller.add(DownloadProgress.cancelled());
          try {
            if (await targetFile.exists()) await targetFile.delete();
          } catch (_) {}
          await controller.close();
          return;
        }

        // Validate File Size
        final actualSize = await targetFile.length();
        if (actualSize == 0 || (totalBytes > 0 && (actualSize - totalBytes).abs() > 1024 * 1024)) {
          controller.add(DownloadProgress.failed('Downloaded file size mismatch. Download may be corrupt.'));
          try {
            await targetFile.delete();
          } catch (_) {}
          await controller.close();
          return;
        }

        // Validate SHA-256 Checksum if present
        if (release.sha256Checksum != null && release.sha256Checksum!.isNotEmpty) {
          controller.add(DownloadProgress.verifying(total: actualSize));
          final fileBytes = await targetFile.readAsBytes();
          final computedDigest = sha256.convert(fileBytes).toString().toLowerCase();

          if (computedDigest != release.sha256Checksum!.toLowerCase()) {
            controller.add(DownloadProgress.failed(
              'Security checksum mismatch. Expected: ${release.sha256Checksum}, Computed: $computedDigest',
            ));
            try {
              await targetFile.delete();
            } catch (_) {}
            await controller.close();
            return;
          }
        }

        controller.add(DownloadProgress.ready(
          filePath: targetFile.path,
          total: actualSize,
        ));
        await controller.close();
      },
      cancelOnError: true,
    );

    yield* controller.stream;
  }

  /// Cancels any active download and safely deletes the partial file.
  Future<void> cancelDownload() async {
    _isCancelled = true;
    try {
      await _currentSubscription?.cancel();
      _currentSubscription = null;
      await _currentFileSink?.flush();
      await _currentFileSink?.close();
      _currentFileSink = null;
      if (_currentTempFile != null && await _currentTempFile!.exists()) {
        await _currentTempFile!.delete();
      }
    } catch (_) {}
  }
}
