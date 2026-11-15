/// Sanitizer that scrubs private credentials, tokens, OTPs, and personal paths
/// from error messages, stack traces, and diagnostics before submission.
class DiagnosticSanitizer {
  static final RegExp _geminiApiKeyRegex =
      RegExp(r'AIza[0-9A-Za-z\-_]{35}', caseSensitive: false);

  static final RegExp _genericApiKeyRegex = RegExp(
      r'(key|apiKey|token|secret)\s*[:=]\s*([A-Za-z0-9_\-]{16,})',
      caseSensitive: false);

  static final RegExp _bearerTokenRegex =
      RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false);

  static final RegExp _jwtTokenRegex =
      RegExp(r'eyJ[A-Za-z0-9\-_=]+\.eyJ[A-Za-z0-9\-_=]+\.[A-Za-z0-9\-_.+/=]+');

  static final RegExp _passwordRegex = RegExp(
      r'(password|passwd|pin|secret|client_secret)\s*[:=]\s*([^\s,;]+)',
      caseSensitive: false);

  static final RegExp _otpRegex = RegExp(
      r'\b(otp|verification\s*code|auth\s*code)\s*[:=]?\s*\d{4,8}\b',
      caseSensitive: false);

  static final RegExp _windowsUserPathRegex =
      RegExp(r'[a-zA-Z]:\\Users\\[^\\]+\\', caseSensitive: false);

  static final RegExp _unixUserPathRegex =
      RegExp(r'/home/[^/]+/', caseSensitive: false);

  /// Sanitizes an input string by redacting all identified secrets.
  static String sanitize(String? input) {
    if (input == null || input.isEmpty) return '';

    var sanitized = input;

    // 1. Redact Google / Firebase / Gemini API keys
    sanitized = sanitized.replaceAll(_geminiApiKeyRegex, '[REDACTED_API_KEY]');

    // 2. Redact Bearer tokens
    sanitized =
        sanitized.replaceAll(_bearerTokenRegex, 'Bearer [REDACTED_TOKEN]');

    // 3. Redact JWTs
    sanitized = sanitized.replaceAll(_jwtTokenRegex, '[REDACTED_JWT]');

    // 4. Redact Passwords
    sanitized = sanitized.replaceAllMapped(_passwordRegex, (m) {
      final key = m.group(1);
      return '$key: [REDACTED_CREDENTIAL]';
    });

    // 5. Redact OTPs
    sanitized = sanitized.replaceAllMapped(_otpRegex, (m) {
      final key = m.group(1);
      return '$key: [REDACTED_OTP]';
    });

    // 6. Redact generic high-entropy API key assignments
    sanitized = sanitized.replaceAllMapped(_genericApiKeyRegex, (m) {
      final key = m.group(1);
      return '$key: [REDACTED_KEY]';
    });

    // 7. Redact local developer/user home directories
    sanitized =
        sanitized.replaceAll(_windowsUserPathRegex, r'C:\Users\[USERNAME]\');
    sanitized = sanitized.replaceAll(_unixUserPathRegex, '/home/[USERNAME]/');

    return sanitized;
  }

  /// Sanitizes a list of system logs.
  static List<String> sanitizeLogs(List<String> logs) {
    return logs.map((log) => sanitize(log)).toList();
  }
}
