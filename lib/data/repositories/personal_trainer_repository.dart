import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/services/personal_trainer_service.dart';
import 'package:forma/data/models/trainer_message_model.dart';
import 'package:forma/data/repositories/workout_repository.dart';
import 'package:forma/data/repositories/nutrition_repository.dart';
import 'package:forma/data/repositories/habit_repository.dart';

final personalTrainerBackendServiceProvider =
    Provider<PersonalTrainerBackendService>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  return PersonalTrainerBackendService(
      directApiKey: apiKey.isNotEmpty ? apiKey : null);
});

class PersonalTrainerState {
  final List<TrainerMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  const PersonalTrainerState({
    required this.messages,
    this.isLoading = false,
    this.errorMessage,
  });

  PersonalTrainerState copyWith({
    List<TrainerMessage>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PersonalTrainerState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PersonalTrainerNotifier extends StateNotifier<PersonalTrainerState> {
  final PersonalTrainerBackendService _service;
  final Ref _ref;

  PersonalTrainerNotifier(this._service, this._ref)
      : super(
          PersonalTrainerState(
            messages: [
              TrainerMessage(
                id: 'welcome_1',
                text: "Hi! What would you like help with today?",
                sender: MessageSender.trainer,
                timestamp: DateTime.now(),
              ),
            ],
          ),
        );

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || state.isLoading) return;

    final userMsg = TrainerMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: clean,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      errorMessage: null,
    );

    // Prepare contextual records
    final workouts = await _ref.read(workoutTemplatesProvider.future);
    final meals = await _ref.read(todayMealsProvider.future);
    final habits = await _ref.read(habitsListProvider.future);
    final habitStatus = _ref.read(habitStatusProvider);

    final recentWorkoutName =
        workouts.isNotEmpty ? workouts.first.name : 'Push Day';
    final totalCalories =
        meals.fold<double>(0, (sum, m) => sum + m.totalCalories);
    final totalProtein =
        meals.fold<double>(0, (sum, m) => sum + m.totalProtein);
    final completedHabits =
        habits.where((h) => habitStatus[h.id] == true).length;

    final contextData = {
      'recentWorkout': recentWorkoutName,
      'loggedCalories': '${totalCalories.toInt()}',
      'loggedProtein': '${totalProtein.toInt()}g',
      'habitsStatus':
          '$completedHabits of ${habits.length} habits completed today',
    };

    final history = state.messages
        .where((m) => !m.isError)
        .map((m) => {
              'role': m.sender == MessageSender.user ? 'user' : 'model',
              'content': m.text,
            })
        .toList();

    try {
      final responseText = await _service.askTrainer(
        userQuestion: clean,
        conversationHistory: history,
        userContext: contextData,
      );

      final lowerQ = clean.toLowerCase();
      final isPersonal = lowerQ.contains('my workout') ||
          lowerQ.contains('my meal') ||
          lowerQ.contains('my habit') ||
          lowerQ.contains('what did i') ||
          lowerQ.contains('my progress') ||
          lowerQ.contains('today');

      // Only extract authentic citations/links if explicitly present in the response
      final sources = <TrainerSource>[];
      final linkRegex = RegExp(r'\[([^\]]+)\]\((https?://[^\)]+)\)');
      final matches = linkRegex.allMatches(responseText);
      for (final match in matches) {
        final title = match.group(1)?.trim() ?? '';
        final url = match.group(2)?.trim() ?? '';
        if (title.isNotEmpty && url.isNotEmpty) {
          if (!sources.any((s) => s.url == url)) {
            final host =
                Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? 'Source';
            sources.add(TrainerSource(
              name: host,
              title: title,
              url: url,
            ));
          }
        }
      }

      final trainerMsg = TrainerMessage(
        id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
        text: responseText,
        sender: MessageSender.trainer,
        timestamp: DateTime.now(),
        isPersonalDataBased: isPersonal,
        sources: sources,
      );

      state = state.copyWith(
        messages: [...state.messages, trainerMsg],
        isLoading: false,
      );
    } catch (_) {
      final errorMsg = TrainerMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        text:
            "Your trainer is temporarily unavailable. Please check your connection and try again.",
        sender: MessageSender.trainer,
        timestamp: DateTime.now(),
        isError: true,
      );

      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        errorMessage:
            "Your trainer is temporarily unavailable. Please try again.",
      );
    }
  }

  void startNewConversation() {
    state = PersonalTrainerState(
      messages: [
        TrainerMessage(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          text: "Hi! What would you like help with today?",
          sender: MessageSender.trainer,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }
}

final personalTrainerProvider =
    StateNotifierProvider<PersonalTrainerNotifier, PersonalTrainerState>((ref) {
  final service = ref.watch(personalTrainerBackendServiceProvider);
  return PersonalTrainerNotifier(service, ref);
});
