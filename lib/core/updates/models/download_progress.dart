import 'package:flutter/foundation.dart';

enum DownloadStatus {
  idle,
  downloading,
  verifying,
  readyToInstall,
  installing,
  cancelled,
  failed,
}

@immutable
class DownloadProgress {
  final DownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final double progress; // 0.0 to 1.0
  final double speedBytesPerSec;
  final String? downloadedFilePath;
  final String? errorMessage;

  const DownloadProgress({
    required this.status,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.progress = 0.0,
    this.speedBytesPerSec = 0.0,
    this.downloadedFilePath,
    this.errorMessage,
  });

  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isVerifying => status == DownloadStatus.verifying;
  bool get isReadyToInstall => status == DownloadStatus.readyToInstall;
  bool get isFailed => status == DownloadStatus.failed;

  String get formattedReceivedSize => formatBytes(receivedBytes);
  String get formattedTotalSize => formatBytes(totalBytes);
  String get formattedSpeed => '${formatBytes(speedBytesPerSec.toInt())}/s';

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  factory DownloadProgress.idle() {
    return const DownloadProgress(status: DownloadStatus.idle);
  }

  factory DownloadProgress.downloading({
    required int received,
    required int total,
    required double speed,
  }) {
    final frac = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
    return DownloadProgress(
      status: DownloadStatus.downloading,
      receivedBytes: received,
      totalBytes: total,
      progress: frac,
      speedBytesPerSec: speed,
    );
  }

  factory DownloadProgress.verifying({required int total}) {
    return DownloadProgress(
      status: DownloadStatus.verifying,
      receivedBytes: total,
      totalBytes: total,
      progress: 1.0,
    );
  }

  factory DownloadProgress.ready(
      {required String filePath, required int total}) {
    return DownloadProgress(
      status: DownloadStatus.readyToInstall,
      receivedBytes: total,
      totalBytes: total,
      progress: 1.0,
      downloadedFilePath: filePath,
    );
  }

  factory DownloadProgress.installing({required String filePath}) {
    return DownloadProgress(
      status: DownloadStatus.installing,
      progress: 1.0,
      downloadedFilePath: filePath,
    );
  }

  factory DownloadProgress.cancelled() {
    return const DownloadProgress(status: DownloadStatus.cancelled);
  }

  factory DownloadProgress.failed(String error) {
    return DownloadProgress(
      status: DownloadStatus.failed,
      errorMessage: error,
    );
  }
}
