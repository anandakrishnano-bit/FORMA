import 'package:cloud_firestore/cloud_firestore.dart';

/// Truthful, auditable Daily Summary & Energy Score model.
///
/// ZERO FAKE DATA GUARANTEE:
/// - energyScore is null or 0 when there is insufficient data.
/// - hasSufficientData explicitly flags whether a score could be legitimately derived.
/// - contributingSources and missingSources track provenance.
class DailySummary {
  final String date;
  final bool hasSufficientData;
  final int? energyScore;
  final String scoringRationale;
  final int steps;
  final double activeCalories;
  final double consumedCalories;
  final double? heartRateBpm;
  final int waterMl;
  final List<String> contributingSources;
  final List<String> missingSources;
  final String overview;
  final String workoutSummary;
  final String nutritionSummary;
  final String habitsSummary;
  final String highlight;
  final String suggestionForTomorrow;
  final String syncStatus; // 'synced', 'pending_sync', 'offline'
  final DateTime? lastSyncedAt;
  final String timezone;

  const DailySummary({
    required this.date,
    this.hasSufficientData = false,
    this.energyScore,
    this.scoringRationale =
        'Not enough activity data to calculate your score yet.',
    this.steps = 0,
    this.activeCalories = 0.0,
    this.consumedCalories = 0.0,
    this.heartRateBpm,
    this.waterMl = 0,
    this.contributingSources = const [],
    this.missingSources = const [],
    required this.overview,
    required this.workoutSummary,
    required this.nutritionSummary,
    required this.habitsSummary,
    required this.highlight,
    required this.suggestionForTomorrow,
    this.syncStatus = 'synced',
    this.lastSyncedAt,
    this.timezone = 'UTC',
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'hasSufficientData': hasSufficientData,
      'energyScore': energyScore,
      'scoringRationale': scoringRationale,
      'steps': steps,
      'activeCalories': activeCalories,
      'consumedCalories': consumedCalories,
      'heartRateBpm': heartRateBpm,
      'waterMl': waterMl,
      'contributingSources': contributingSources,
      'missingSources': missingSources,
      'overview': overview,
      'workoutSummary': workoutSummary,
      'nutritionSummary': nutritionSummary,
      'habitsSummary': habitsSummary,
      'highlight': highlight,
      'suggestionForTomorrow': suggestionForTomorrow,
      'syncStatus': syncStatus,
      'lastSyncedAt': lastSyncedAt != null
          ? Timestamp.fromDate(lastSyncedAt!)
          : FieldValue.serverTimestamp(),
      'timezone': timezone,
    };
  }

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      date: map['date'] as String? ?? '',
      hasSufficientData: map['hasSufficientData'] as bool? ?? false,
      energyScore: (map['energyScore'] as num?)?.toInt(),
      scoringRationale: map['scoringRationale'] as String? ??
          'Not enough activity data to calculate your score yet.',
      steps: (map['steps'] as num?)?.toInt() ?? 0,
      activeCalories: (map['activeCalories'] as num?)?.toDouble() ?? 0.0,
      consumedCalories: (map['consumedCalories'] as num?)?.toDouble() ?? 0.0,
      heartRateBpm: (map['heartRateBpm'] as num?)?.toDouble(),
      waterMl: (map['waterMl'] as num?)?.toInt() ?? 0,
      contributingSources:
          (map['contributingSources'] as List<dynamic>?)?.cast<String>() ??
              const [],
      missingSources:
          (map['missingSources'] as List<dynamic>?)?.cast<String>() ?? const [],
      overview: map['overview'] as String? ?? '',
      workoutSummary: map['workoutSummary'] as String? ?? '',
      nutritionSummary: map['nutritionSummary'] as String? ?? '',
      habitsSummary: map['habitsSummary'] as String? ?? '',
      highlight: map['highlight'] as String? ?? '',
      suggestionForTomorrow: map['suggestionForTomorrow'] as String? ?? '',
      syncStatus: map['syncStatus'] as String? ?? 'synced',
      lastSyncedAt: (map['lastSyncedAt'] as Timestamp?)?.toDate(),
      timezone: map['timezone'] as String? ?? 'UTC',
    );
  }
}
