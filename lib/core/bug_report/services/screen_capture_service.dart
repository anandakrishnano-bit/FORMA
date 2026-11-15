import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

/// Service responsible for secure screen captures, sensitive screen exclusion,
/// image picking, and client-side compression.
class ScreenCaptureService {
  ScreenCaptureService._();
  static final ScreenCaptureService instance = ScreenCaptureService._();

  /// Global key attached to the root RepaintBoundary of the application.
  final GlobalKey rootRepaintBoundaryKey = GlobalKey();

  final ImagePicker _picker = ImagePicker();

  /// Routes that MUST NEVER be automatically captured to preserve user confidentiality.
  static const Set<String> sensitiveRoutes = {
    '/welcome',
    '/login',
    '/splash',
    '/onboarding',
    '/auth/action',
    '/profile/security-settings',
    '/user-api-key-settings',
    '/shared-expenses/settle-up',
  };

  /// Tracks the most recent non-bug-report route visited by the user.
  String lastVisitedRoute = '/home';

  void updateLastVisitedRoute(String route) {
    if (!route.startsWith('/profile/help/report-problem')) {
      lastVisitedRoute = route;
    }
  }

  /// Returns true if the provided route or last visited route is classified as sensitive.
  bool isRouteSensitive([String? route]) {
    final checkRoute = route ?? lastVisitedRoute;
    return sensitiveRoutes.any((sensitive) =>
        checkRoute.toLowerCase().startsWith(sensitive.toLowerCase()));
  }

  /// Attempts to capture the current visible screen from the root RepaintBoundary.
  /// Throws [StateError] or returns null if the target screen is sensitive or boundary is unavailable.
  Future<Uint8List?> captureScreen({bool enforceSensitiveCheck = true}) async {
    if (enforceSensitiveCheck && isRouteSensitive(lastVisitedRoute)) {
      debugPrint(
          '[ScreenCaptureService] Automatic capture blocked: Sensitive screen detected ($lastVisitedRoute).');
      return null;
    }

    try {
      final boundary = rootRepaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('[ScreenCaptureService] RepaintBoundary is not attached.');
        return null;
      }

      // Capture with 1.5 pixel ratio for crisp rendering without excessive memory consumption
      final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, stack) {
      debugPrint('[ScreenCaptureService] Screen capture failed: $e\n$stack');
      return null;
    }
  }

  /// Allows user to pick a screenshot from device storage/gallery.
  Future<Uint8List?> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 82,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('[ScreenCaptureService] Gallery pick error: $e');
      return null;
    }
  }

  /// Allows user to take a fresh photo with the device camera.
  Future<Uint8List?> captureWithCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 82,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('[ScreenCaptureService] Camera capture error: $e');
      return null;
    }
  }
}
