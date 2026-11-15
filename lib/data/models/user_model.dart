import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model stored in Firestore at users/{userId}.
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserPreferences preferences;
  final UserStats stats;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    required this.createdAt,
    required this.updatedAt,
    this.preferences = const UserPreferences(),
    this.stats = const UserStats(),
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: data['preferences'] != null
          ? UserPreferences.fromMap(data['preferences'] as Map<String, dynamic>)
          : const UserPreferences(),
      stats: data['stats'] != null
          ? UserStats.fromMap(data['stats'] as Map<String, dynamic>)
          : const UserStats(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'preferences': preferences.toMap(),
      'stats': stats.toMap(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserPreferences? preferences,
    UserStats? stats,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
    );
  }
}

/// User preferences for app settings and display.
class UserPreferences {
  final bool darkMode;
  final String weightUnit;
  final String distanceUnit;
  final int dailyCalorieTarget;
  final double dailyProteinTarget;
  final double dailyCarbsTarget;
  final double dailyFatTarget;
  final int dailyWaterTarget;
  final bool notificationsEnabled;
  final String workoutReminder;

  const UserPreferences({
    this.darkMode = false,
    this.weightUnit = 'kg',
    this.distanceUnit = 'km',
    this.dailyCalorieTarget = 2000,
    this.dailyProteinTarget = 120.0,
    this.dailyCarbsTarget = 250.0,
    this.dailyFatTarget = 65.0,
    this.dailyWaterTarget = 8,
    this.notificationsEnabled = true,
    this.workoutReminder = '08:00',
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      darkMode: map['darkMode'] as bool? ?? false,
      weightUnit: map['weightUnit'] as String? ?? 'kg',
      distanceUnit: map['distanceUnit'] as String? ?? 'km',
      dailyCalorieTarget: map['dailyCalorieTarget'] as int? ?? 2000,
      dailyProteinTarget:
          (map['dailyProteinTarget'] as num?)?.toDouble() ?? 120.0,
      dailyCarbsTarget: (map['dailyCarbsTarget'] as num?)?.toDouble() ?? 250.0,
      dailyFatTarget: (map['dailyFatTarget'] as num?)?.toDouble() ?? 65.0,
      dailyWaterTarget: map['dailyWaterTarget'] as int? ?? 8,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      workoutReminder: map['workoutReminder'] as String? ?? '08:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'weightUnit': weightUnit,
      'distanceUnit': distanceUnit,
      'dailyCalorieTarget': dailyCalorieTarget,
      'dailyProteinTarget': dailyProteinTarget,
      'dailyCarbsTarget': dailyCarbsTarget,
      'dailyFatTarget': dailyFatTarget,
      'dailyWaterTarget': dailyWaterTarget,
      'notificationsEnabled': notificationsEnabled,
      'workoutReminder': workoutReminder,
    };
  }

  UserPreferences copyWith({
    bool? darkMode,
    String? weightUnit,
    String? distanceUnit,
    int? dailyCalorieTarget,
    double? dailyProteinTarget,
    double? dailyCarbsTarget,
    double? dailyFatTarget,
    int? dailyWaterTarget,
    bool? notificationsEnabled,
    String? workoutReminder,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      weightUnit: weightUnit ?? this.weightUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      dailyProteinTarget: dailyProteinTarget ?? this.dailyProteinTarget,
      dailyCarbsTarget: dailyCarbsTarget ?? this.dailyCarbsTarget,
      dailyFatTarget: dailyFatTarget ?? this.dailyFatTarget,
      dailyWaterTarget: dailyWaterTarget ?? this.dailyWaterTarget,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      workoutReminder: workoutReminder ?? this.workoutReminder,
    );
  }
}

/// Aggregated user stats.
class UserStats {
  final int totalWorkouts;
  final int totalExercisesCompleted;
  final double totalWeightLifted;
  final int currentStreak;
  final int longestStreak;
  final int totalMinutesTrained;

  const UserStats({
    this.totalWorkouts = 0,
    this.totalExercisesCompleted = 0,
    this.totalWeightLifted = 0.0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalMinutesTrained = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalWorkouts: map['totalWorkouts'] as int? ?? 0,
      totalExercisesCompleted: map['totalExercisesCompleted'] as int? ?? 0,
      totalWeightLifted: (map['totalWeightLifted'] as num?)?.toDouble() ?? 0.0,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      totalMinutesTrained: map['totalMinutesTrained'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalWorkouts': totalWorkouts,
      'totalExercisesCompleted': totalExercisesCompleted,
      'totalWeightLifted': totalWeightLifted,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalMinutesTrained': totalMinutesTrained,
    };
  }
}
