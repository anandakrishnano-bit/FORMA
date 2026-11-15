import 'package:flutter/services.dart';

/// Native Android bridge for checking installed package version and
/// handing off APK installations to Android's official PackageInstaller.
class AppUpdatePlatformService {
  static const MethodChannel _channel = MethodChannel('com.forma.app/app_update');

  /// Retrieves the current installed app versionName and versionCode directly from Android PackageManager.
  Future<({String versionName, int versionCode})> getInstalledVersionInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getInstalledVersionInfo');
      if (result != null) {
        final versionName = (result['versionName'] as String?) ?? '1.0.0';
        final versionCode = (result['versionCode'] as num?)?.toInt() ?? 1;
        return (versionName: versionName, versionCode: versionCode);
      }
    } catch (_) {}
    return (versionName: '1.0.0', versionCode: 1);
  }

  /// Checks whether the user has granted "Install unknown apps" permission to FORMA.
  Future<bool> canRequestPackageInstalls() async {
    try {
      final allowed = await _channel.invokeMethod<bool>('canRequestPackageInstalls');
      return allowed ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Directs the user to Android Settings to grant the "Install unknown apps" permission for FORMA.
  Future<bool> openInstallPermissionSettings() async {
    try {
      final success = await _channel.invokeMethod<bool>('openInstallPermissionSettings');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Triggers Android's official PackageInstaller with the secure FileProvider content URI.
  Future<bool> installApk(String filePath) async {
    try {
      final success = await _channel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Failed to launch Android package installer.');
    } catch (e) {
      throw Exception('Could not install package: $e');
    }
  }
}
