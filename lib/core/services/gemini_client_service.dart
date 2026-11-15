import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:forma/core/services/app_logger.dart';

/// Resilient, Auto-Discovering Gemini AI Client.
///
/// Automatically discovers active models supported by the user's individual API key,
/// preventing 404 NOT_FOUND errors due to model deprecation (e.g. gemini-1.5-flash -> gemini-2.0-flash).
class GeminiClientService {
  static String? _cachedModelName;
  static DateTime? _cacheTimestamp;

  static const List<String> _fallbackModelCandidates = [
    'gemini-2.0-flash',
    'gemini-2.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-2.0-flash-exp',
    'gemini-1.5-flash',
    'gemini-pro',
  ];

  /// Queries the Google Generative Language API for models enabled on this API key.
  static Future<String> resolveBestModel(String apiKey) async {
    // Return cached model if resolved within the last 30 minutes
    if (_cachedModelName != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) <
            const Duration(minutes: 30)) {
      return _cachedModelName!;
    }

    AppLogger.info('GEMINI_DISCOVERY',
        'Calling ListModels to discover available models for user key...');

    try {
      final listUrl = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final response =
          await http.get(listUrl).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = (data['models'] as List?) ?? [];

        final availableNames = <String>[];
        for (final m in models) {
          final methods = (m['supportedGenerationMethods'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          if (methods.contains('generateContent')) {
            final rawName = m['name'] as String? ?? '';
            // Remove 'models/' prefix if present
            final cleanName =
                rawName.startsWith('models/') ? rawName.substring(7) : rawName;
            availableNames.add(cleanName);
          }
        }

        AppLogger.info('GEMINI_DISCOVERY',
            'Available models on user account: ${availableNames.take(5).join(", ")}');

        // Check preferred models in priority order
        for (final candidate in _fallbackModelCandidates) {
          if (availableNames.contains(candidate)) {
            _cachedModelName = candidate;
            _cacheTimestamp = DateTime.now();
            AppLogger.success('GEMINI_DISCOVERY',
                'Selected optimal active model: $candidate');
            return candidate;
          }
        }

        // Otherwise find any flash model
        final flashModel = availableNames.firstWhere(
          (m) => m.toLowerCase().contains('flash'),
          orElse: () => '',
        );
        if (flashModel.isNotEmpty) {
          _cachedModelName = flashModel;
          _cacheTimestamp = DateTime.now();
          AppLogger.success(
              'GEMINI_DISCOVERY', 'Selected flash model: $flashModel');
          return flashModel;
        }

        // Fallback to first available model with generateContent
        if (availableNames.isNotEmpty) {
          _cachedModelName = availableNames.first;
          _cacheTimestamp = DateTime.now();
          AppLogger.success('GEMINI_DISCOVERY',
              'Selected available model: ${availableNames.first}');
          return availableNames.first;
        }
      } else {
        AppLogger.warn('GEMINI_DISCOVERY',
            'ListModels returned HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.warn('GEMINI_DISCOVERY',
          'ListModels failed, falling back to priority list: $e');
    }

    // Default fallback
    _cachedModelName = 'gemini-2.0-flash';
    _cacheTimestamp = DateTime.now();
    return _cachedModelName!;
  }

  /// Sends a generateContent request with automatic model resolution and retry on 404.
  static Future<String> generateContent({
    required String apiKey,
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? conversationHistory,
    int maxTokens = 800,
    double temperature = 0.7,
  }) async {
    // 1. Resolve model
    var model = await resolveBestModel(apiKey);

    // 2. Prepare payload
    // Build combined contents for universal compatibility across v1 and v1beta
    final messages = <Map<String, dynamic>>[];

    // If system instruction is provided, merge it into the first turn or payload
    final combinedSystem =
        systemInstruction != null && systemInstruction.isNotEmpty
            ? '$systemInstruction\n\n'
            : '';

    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      bool isFirst = true;
      for (final msg in conversationHistory.take(6)) {
        final text = isFirst && msg['role'] == 'user'
            ? '$combinedSystem${msg['content']}'
            : msg['content']!;
        if (isFirst && msg['role'] == 'user') isFirst = false;

        messages.add({
          'role': msg['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': text}
          ],
        });
      }
      messages.add({
        'role': 'user',
        'parts': [
          {'text': prompt}
        ],
      });
    } else {
      messages.add({
        'role': 'user',
        'parts': [
          {'text': '$combinedSystem$prompt'}
        ],
      });
    }

    final requestBody = json.encode({
      'contents': messages,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      }
    });

    // 3. Attempt execution
    final candidatesToTry = [
      model,
      ..._fallbackModelCandidates.where((m) => m != model),
    ];

    String lastError = '';
    int lastStatusCode = 0;

    for (final candidate in candidatesToTry.take(3)) {
      try {
        AppLogger.info(
            'GEMINI', 'Executing generateContent with model: $candidate...');
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$candidate:generateContent?key=$apiKey',
        );

        final stopwatch = Stopwatch()..start();
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 15));
        stopwatch.stop();

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String;
              _cachedModelName = candidate;
              _cacheTimestamp = DateTime.now();
              AppLogger.success('GEMINI',
                  'Success via $candidate in ${stopwatch.elapsedMilliseconds} ms (${text.length} chars)');
              return text.trim();
            }
          }
          return "Gemini responded with empty content. Please try rephrasing.";
        }

        lastStatusCode = response.statusCode;
        lastError = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;

        // If 404 NOT_FOUND, invalidate cache and try next candidate immediately
        if (response.statusCode == 404) {
          AppLogger.warn('GEMINI',
              'Model $candidate returned 404 NOT_FOUND. Trying alternative active model...');
          _cachedModelName = null;
          continue;
        }

        // If other error (e.g. 400 Bad Request, 403 Forbidden, 429 Quota), break and report
        AppLogger.error('GEMINI',
            'HTTP ${response.statusCode} from $candidate: $lastError');
        break;
      } catch (e) {
        AppLogger.warn('GEMINI', 'Request attempt failed for $candidate: $e');
        lastError = e.toString();
      }
    }

    throw Exception('Gemini API Error (HTTP $lastStatusCode): $lastError');
  }

  /// Reset cache
  static void invalidateCache() {
    _cachedModelName = null;
    _cacheTimestamp = null;
  }
}
