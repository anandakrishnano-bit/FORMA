import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Android Native File Export and System Share Integration.
///
/// Implements:
/// 1. Native Android Sharesheet (share_plus) - sharing workout plans and summaries.
/// 2. CSV/JSON export and saving without overwriting.
class AndroidIntegrationService {
  // ═════════════════════════════════════════════════════════════════════════
  // ANDROID SHARESHEET
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> shareWorkoutSummary({
    required String workoutName,
    required int totalExercises,
    required double totalVolumeKg,
  }) async {
    final text = '''
FORMA Workout Completed!
Workout: $workoutName
Exercises: $totalExercises
Volume: ${totalVolumeKg.toInt()} kg lifted

Tracked with FORMA.
''';

    await SharePlus.instance
        .share(ShareParams(text: text, subject: 'My FORMA Workout'));
  }

  Future<void> shareFile(File file, {String? text}) async {
    await SharePlus.instance
        .share(ShareParams(files: [XFile(file.path)], text: text));
  }

  // ═════════════════════════════════════════════════════════════════════════
  // EXPORT HISTORY TO CSV
  // ═════════════════════════════════════════════════════════════════════════

  Future<File> exportWorkoutHistoryToCsv(
      List<Map<String, dynamic>> records) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/forma_workout_history_$timestamp.csv');

    final buffer = StringBuffer();
    buffer.writeln('Date,Workout,Exercises,VolumeKg,DurationMin');

    for (final row in records) {
      buffer.writeln(
        '${row['date']},${row['name']},${row['exercises']},${row['volume']},${row['duration']}',
      );
    }

    await file.writeAsString(buffer.toString());
    return file;
  }
}
