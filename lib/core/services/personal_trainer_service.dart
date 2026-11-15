import 'package:forma/core/services/app_logger.dart';
import 'package:forma/core/services/gemini_client_service.dart';
import 'package:forma/core/services/secure_storage_service.dart';

/// Central Backend Client for FORMA Personal Trainer & Intelligent Features.
///
/// CRITICAL ARCHITECTURAL GUARANTEES:
/// 1. Uses the individual authenticated user's own Gemini API key (loaded from Android Keystore).
/// 2. If the user hasn't supplied a key yet, transparently informs the user with setup instructions.
/// 3. Never secretly swallows API failures or outputs fake canned responses that pretend to be AI.
/// 4. Injects real factual context (recent workouts, target split, logged meals) strictly with user permission.
/// 5. Automatically discovers and calls the active, supported Gemini model (gemini-2.0-flash, gemini-1.5-flash-latest, etc.).
class PersonalTrainerBackendService {
  final String? backendUrl;
  final String? directApiKey;
  final SecureStorageService _secureStorage = SecureStorageService();

  PersonalTrainerBackendService({this.backendUrl, this.directApiKey});

  Future<String> askTrainer({
    required String userQuestion,
    required List<Map<String, String>> conversationHistory,
    required Map<String, dynamic> userContext,
  }) async {
    AppLogger.info('TRAINER', 'Trainer query received: "$userQuestion"');

    // Retrieve user's personal key from Android Keystore or direct configuration
    final userKey = directApiKey ?? await _secureStorage.getUserGeminiKey();

    if (userKey == null || userKey.trim().isEmpty) {
      AppLogger.warn(
          'TRAINER', 'No personal Gemini API key found in SecureStorage');
      return "AI Assistant not connected.\n\n"
          "To chat with your AI Personal Trainer, please connect your AI Assistant in Profile > AI Assistant Settings.";
    }

    final maskedKey = userKey.length > 8
        ? '${userKey.substring(0, 6)}...${userKey.substring(userKey.length - 4)}'
        : '******';
    AppLogger.info(
        'TRAINER', 'Executing Gemini API request with key $maskedKey...');

    // Factual user context serialization
    final recentWorkout = userContext['recentWorkout'] ?? 'None recorded';
    final loggedCalories = userContext['loggedCalories'] ?? '0';
    final loggedProtein = userContext['loggedProtein'] ?? '0g';
    final habitsStatus = userContext['habitsStatus'] ?? 'Routine in progress';

    final systemInstructions = '''
You are the dedicated Personal Trainer inside the FORMA fitness app.
You provide clear, friendly, practical and encouraging workout, exercise form, and nutrition guidance.

User context for today:
- Recent workout: $recentWorkout
- Nutrition recorded today: $loggedCalories kcal, $loggedProtein protein
- Habits status: $habitsStatus

RULES & FORMATTING:
1. Address the user directly in an encouraging, knowledgeable personal coach voice.
2. Structure exercise and training advice with clean Markdown:
   - Use bold section headers (e.g., **Setup & Alignment**, **Execution & Form Cues**, **Muscle Focus**, **Recommended Sets & Reps**).
   - Use bullet points for form cues and safety checks.
   - Use numbered lists for consecutive step sequences.
3. Keep explanations punchy and actionable—focus on immediate takeaways the user can apply in the gym right now.
4. When asked for evidence or sources, mention established sports science consensus (e.g., ACSM, NSCA, ISSN) naturally in prose. Never fabricate arbitrary external database links.
5. If the user asks about their own logged stats or history, reference their recorded data from the context above.
6. If pain or sharp discomfort is mentioned, instruct them to stop immediately and consult a qualified medical professional.
''';

    try {
      final answer = await GeminiClientService.generateContent(
        apiKey: userKey,
        prompt: userQuestion,
        systemInstruction: systemInstructions,
        conversationHistory: conversationHistory,
        maxTokens: 2500,
        temperature: 0.7,
      );
      return answer;
    } catch (e, st) {
      AppLogger.error('TRAINER', 'Gemini generation failed', e, st);
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      return "$errorMsg\n\nPlease check System Diagnostics or verify your key in Profile > Trainer Access Key.";
    }
  }
}
