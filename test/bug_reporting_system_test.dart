import 'package:flutter_test/flutter_test.dart';
import 'package:forma/core/bug_report/models/bug_report_category.dart';
import 'package:forma/core/bug_report/models/bug_report_status.dart';
import 'package:forma/core/bug_report/models/bug_report_model.dart';
import 'package:forma/core/bug_report/services/diagnostic_sanitizer.dart';
import 'package:forma/core/bug_report/services/screen_capture_service.dart';

void main() {
  group('BugReportCategory & Status Model Tests', () {
    test('Categories resolve accurately from ID with sensible fallback', () {
      expect(BugReportCategory.fromId('crash'), BugReportCategory.crash);
      expect(BugReportCategory.fromId('display'), BugReportCategory.display);
      expect(BugReportCategory.fromId('auth'), BugReportCategory.auth);
      expect(BugReportCategory.fromId('incorrect_info'),
          BugReportCategory.incorrectInfo);
      expect(BugReportCategory.fromId('feature'), BugReportCategory.feature);
      expect(BugReportCategory.fromId('performance'),
          BugReportCategory.performance);
      expect(BugReportCategory.fromId('other'), BugReportCategory.other);
      expect(BugReportCategory.fromId('unknown_id'), BugReportCategory.other);
      expect(BugReportCategory.fromId(null), BugReportCategory.other);
    });

    test('Statuses resolve accurately from ID with sensible fallback', () {
      expect(BugReportStatus.fromId('new'), BugReportStatus.newReport);
      expect(BugReportStatus.fromId('investigating'),
          BugReportStatus.investigating);
      expect(BugReportStatus.fromId('fixed'), BugReportStatus.fixed);
      expect(BugReportStatus.fromId('cannot_reproduce'),
          BugReportStatus.cannotReproduce);
      expect(BugReportStatus.fromId('closed'), BugReportStatus.closed);
      expect(
          BugReportStatus.fromId('unknown_status'), BugReportStatus.newReport);
      expect(BugReportStatus.fromId(null), BugReportStatus.newReport);
    });
  });

  group('DiagnosticSanitizer Security & Redaction Tests', () {
    test('Redacts Google and Gemini API keys', () {
      const raw =
          'Error initializing GeminiClient with key AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q failed with HTTP 403';
      final sanitized = DiagnosticSanitizer.sanitize(raw);
      expect(sanitized,
          isNot(contains('AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q')));
      expect(sanitized, contains('[REDACTED_API_KEY]'));
    });

    test('Redacts Bearer authorization tokens', () {
      const raw =
          'Request header: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.tokenpayload.signature';
      final sanitized = DiagnosticSanitizer.sanitize(raw);
      expect(sanitized, isNot(contains('tokenpayload')));
      expect(sanitized, contains('Bearer [REDACTED_TOKEN]'));
    });

    test('Redacts Passwords, PINs, and Credentials', () {
      const raw =
          'Auth payload: {username: "athlete", password: "SuperSecretPassword123!", pin: 9876}';
      final sanitized = DiagnosticSanitizer.sanitize(raw);
      expect(sanitized, isNot(contains('SuperSecretPassword123!')));
      expect(sanitized, contains('password: [REDACTED_CREDENTIAL]'));
      expect(sanitized, contains('pin: [REDACTED_CREDENTIAL]'));
    });

    test('Redacts OTP and Verification Codes', () {
      const raw = 'Phone auth callback: otp: 839201 verified against Firebase';
      final sanitized = DiagnosticSanitizer.sanitize(raw);
      expect(sanitized, isNot(contains('839201')));
      expect(sanitized, contains('otp: [REDACTED_OTP]'));
    });

    test('Redacts local Windows and Unix user directory paths', () {
      const rawWin =
          r'Exception in C:\Users\john_doe\AppData\Local\Temp\flutter_assets\image.png';
      final sanitizedWin = DiagnosticSanitizer.sanitize(rawWin);
      expect(sanitizedWin, isNot(contains('john_doe')));
      expect(sanitizedWin, contains(r'C:\Users\[USERNAME]\'));

      const rawUnix = '/home/sarah_connor/projects/forma/lib/main.dart:12:4';
      final sanitizedUnix = DiagnosticSanitizer.sanitize(rawUnix);
      expect(sanitizedUnix, isNot(contains('sarah_connor')));
      expect(sanitizedUnix, contains('/home/[USERNAME]/'));
    });

    test('Preserves clean stack traces and error messages without secret loss',
        () {
      const raw =
          'RenderFlex overflowed by 24 pixels on bottom: WorkoutExecutionScreen (workout_execution_screen.dart:142)';
      final sanitized = DiagnosticSanitizer.sanitize(raw);
      expect(sanitized, equals(raw));
    });
  });

  group('ScreenCaptureService Sensitive Route Detection Tests', () {
    final captureService = ScreenCaptureService.instance;

    test('Identifies authentication and payment screens as strictly sensitive',
        () {
      expect(captureService.isRouteSensitive('/login'), isTrue);
      expect(captureService.isRouteSensitive('/welcome'), isTrue);
      expect(captureService.isRouteSensitive('/splash'), isTrue);
      expect(captureService.isRouteSensitive('/onboarding-flow'), isTrue);
      expect(captureService.isRouteSensitive('/profile/security-settings'),
          isTrue);
      expect(captureService.isRouteSensitive('/user-api-key-settings'), isTrue);
      expect(captureService.isRouteSensitive('/shared-expenses/settle-up'),
          isTrue);
    });

    test('Permits screen capture on normal application screens', () {
      expect(captureService.isRouteSensitive('/home'), isFalse);
      expect(captureService.isRouteSensitive('/workout'), isFalse);
      expect(captureService.isRouteSensitive('/workout/execution'), isFalse);
      expect(captureService.isRouteSensitive('/nutrition'), isFalse);
      expect(captureService.isRouteSensitive('/habits'), isFalse);
      expect(captureService.isRouteSensitive('/expenses'), isFalse);
      expect(captureService.isRouteSensitive('/profile'), isFalse);
    });
  });

  group('BugReportModel Serialization & Reference Tests', () {
    test('Generates structured reference codes', () {
      final code1 = BugReportModel.generateReferenceCode(
          'a1b2c3d4-e5f6-7890-1234-567890abcdef');
      expect(code1, startsWith('FRM-'));
      expect(code1.length, equals(13)); // FRM-XXXX-XXXX = 3+1+4+1+4 = 13

      final code2 = BugReportModel.generateReferenceCode();
      expect(code2, startsWith('FRM-'));
    });

    test('Full serialization to and from Map preserves all fields', () {
      final now = DateTime.now();
      final report = BugReportModel(
        id: 'test-report-1234',
        referenceCode: 'FRM-TEST-1234',
        userId: 'user_abc_789',
        userEmail: 'athlete@forma.app',
        userDisplayName: 'Alex Stark',
        category: BugReportCategory.display,
        description: 'Workout chart bar clipping on tablet screen',
        expectedBehavior: 'All bars should scale down to fit container width',
        status: BugReportStatus.investigating,
        deviceInfo: {
          'manufacturer': 'Google',
          'model': 'Pixel Tablet',
          'androidRelease': '14',
          'sdkInt': 34,
        },
        appInfo: {
          'appName': 'FORMA',
          'version': '1.0.1',
          'buildNumber': '2',
          'currentRoute': '/workout',
        },
        diagnostics: {
          'recentLogs': ['Log 1', 'Log 2'],
          'lastError': 'None',
        },
        screenshotUrl:
            'https://storage.googleapis.com/forma-app/screenshot.jpg',
        screenshotStoragePath:
            'bug-reports/user_abc_789/test-report-1234/screenshot.jpg',
        internalNotes: 'Confirmed in emulator with 600dp width',
        associatedFixRelease: 'v1.0.2',
        createdAt: now,
        updatedAt: now,
      );

      final jsonMap = report.toJson();
      final restored = BugReportModel.fromMap(jsonMap);

      expect(restored.id, equals(report.id));
      expect(restored.referenceCode, equals(report.referenceCode));
      expect(restored.userId, equals(report.userId));
      expect(restored.userEmail, equals(report.userEmail));
      expect(restored.category, equals(BugReportCategory.display));
      expect(restored.status, equals(BugReportStatus.investigating));
      expect(restored.description, equals(report.description));
      expect(restored.expectedBehavior, equals(report.expectedBehavior));
      expect(restored.deviceInfo['model'], equals('Pixel Tablet'));
      expect(restored.internalNotes,
          equals('Confirmed in emulator with 600dp width'));
      expect(restored.associatedFixRelease, equals('v1.0.2'));
    });
  });
}
