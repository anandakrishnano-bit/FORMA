import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:forma/core/services/app_logger.dart';
import 'diagnostic_sanitizer.dart';
import 'screen_capture_service.dart';

/// Service that queries device specifications, operating system details,
/// and packages sanitized application logs into a lightweight diagnostic snapshot.
class DeviceDiagnosticService {
  final DeviceInfoPlugin _deviceInfoPlugin;

  DeviceDiagnosticService({DeviceInfoPlugin? deviceInfoPlugin})
      : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  /// Collects Android device hardware, OS version, and manufacturer metadata.
  Future<Map<String, dynamic>> collectDeviceInfo() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        return {
          'platform': 'web',
          'browser': webInfo.browserName.name,
          'userAgent': webInfo.userAgent,
        };
      }

      if (Platform.isAndroid) {
        final android = await _deviceInfoPlugin.androidInfo;
        return {
          'platform': 'android',
          'brand': android.brand,
          'manufacturer': android.manufacturer,
          'model': android.model,
          'device': android.device,
          'hardware': android.hardware,
          'androidRelease': android.version.release,
          'sdkInt': android.version.sdkInt,
          'isPhysicalDevice': android.isPhysicalDevice,
          'supportedAbis': android.supportedAbis,
        };
      }

      if (Platform.isIOS) {
        final ios = await _deviceInfoPlugin.iosInfo;
        return {
          'platform': 'ios',
          'model': ios.utsname.machine,
          'systemName': ios.systemName,
          'systemVersion': ios.systemVersion,
          'isPhysicalDevice': ios.isPhysicalDevice,
        };
      }

      return {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      };
    } catch (e) {
      debugPrint('[DeviceDiagnosticService] Failed to query device info: $e');
      return {
        'platform': 'unknown',
        'error': e.toString(),
      };
    }
  }

  /// Collects standard application build and routing metadata.
  Map<String, dynamic> collectAppInfo() {
    return {
      'appName': 'FORMA',
      'packageName': 'com.forma.app',
      'version': '1.0.1',
      'buildNumber': '2',
      'currentRoute': ScreenCaptureService.instance.lastVisitedRoute,
    };
  }

  /// Collects sanitized diagnostic log entries and error traces.
  Map<String, dynamic> collectDiagnostics() {
    final rawLogs = AppLogger.getLogs();
    final recentEntries =
        rawLogs.length > 35 ? rawLogs.sublist(rawLogs.length - 35) : rawLogs;

    final sanitizedLogs = recentEntries
        .map((e) => DiagnosticSanitizer.sanitize(e.toString()))
        .toList();

    // Look for the most recent error entry, if any
    final lastErrorEntry = rawLogs.reversed.firstWhere(
      (e) => e.level == AppLogLevel.error && e.errorDetails != null,
      orElse: () => AppLogEntry(
        timestamp: DateTime.now(),
        tag: 'SYSTEM',
        message: 'No fatal errors recorded in buffer',
        level: AppLogLevel.info,
      ),
    );

    return {
      'recentLogs': sanitizedLogs,
      'lastError':
          DiagnosticSanitizer.sanitize(lastErrorEntry.errorDetails ?? 'None'),
      'lastErrorTag': lastErrorEntry.tag,
      'reportedAt': DateTime.now().toIso8601String(),
    };
  }
}
