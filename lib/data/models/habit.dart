import 'package:flutter/material.dart';

/// Frequency types for habits.
enum HabitFrequency {
  daily,
  selectedDays,
  weeklyTarget,
  custom,
}

extension HabitFrequencyExtension on HabitFrequency {
  String get displayName {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.selectedDays:
        return 'Specific Days';
      case HabitFrequency.weeklyTarget:
        return 'Weekly Target';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }
}

/// A user-defined habit.
class Habit {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final int iconCodePoint;
  final Color color;
  final int colorValue;
  final String? description;
  final HabitFrequency frequency;
  final List<int>? selectedDays; // 1=Mon .. 7=Sun
  final int? weeklyTarget;
  final bool hasReminder;
  final TimeOfDay? reminderTime;
  final DateTime startDate;
  final DateTime createdAt;
  final bool isArchived;
  final int sortOrder;
  final int streakCount;

  String get title => name;
  String get category => frequency.displayName;

  Habit({
    required this.id,
    this.userId = '',
    String? name,
    String? title,
    String? icon,
    int? iconCodePoint,
    Color? color,
    int? colorValue,
    this.description,
    dynamic frequency = HabitFrequency.daily,
    this.selectedDays,
    this.weeklyTarget,
    this.hasReminder = false,
    this.reminderTime,
    DateTime? startDate,
    DateTime? createdAt,
    this.isArchived = false,
    this.sortOrder = 0,
    this.streakCount = 0,
  })  : name = name ?? (title ?? ''),
        icon = icon ?? '',
        iconCodePoint = iconCodePoint ?? 0xe28d,
        color = color ??
            (colorValue != null ? Color(colorValue) : const Color(0xFFFFC443)),
        colorValue = colorValue ?? (color?.toARGB32() ?? 0xFFFFC443),
        startDate = startDate ?? (createdAt ?? DateTime.now()),
        createdAt = createdAt ?? DateTime.now(),
        frequency = frequency is HabitFrequency
            ? frequency
            : (frequency == 'Daily'
                ? HabitFrequency.daily
                : HabitFrequency.daily);

  Habit copyWith({
    String? id,
    String? name,
    String? icon,
    Color? color,
    String? description,
    HabitFrequency? frequency,
    List<int>? selectedDays,
    int? weeklyTarget,
    bool? hasReminder,
    TimeOfDay? reminderTime,
    DateTime? startDate,
    DateTime? createdAt,
    bool? isArchived,
    int? sortOrder,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      selectedDays: selectedDays ?? this.selectedDays,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Whether this habit is scheduled for the given [date].
  bool isScheduledFor(DateTime date) {
    if (date
        .isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
      return false;
    }
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.selectedDays:
        return selectedDays?.contains(date.weekday) ?? false;
      case HabitFrequency.weeklyTarget:
        return true; // always shows, user picks when to do it
      case HabitFrequency.custom:
        return true;
    }
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: Color(json['color'] as int),
      description: json['description'] as String?,
      frequency: HabitFrequency.values[json['frequency'] as int? ?? 0],
      selectedDays: (json['selectedDays'] as List?)?.cast<int>(),
      weeklyTarget: json['weeklyTarget'] as int?,
      hasReminder: json['hasReminder'] as bool? ?? false,
      reminderTime: json['reminderHour'] != null
          ? TimeOfDay(
              hour: json['reminderHour'] as int,
              minute: json['reminderMinute'] as int? ?? 0,
            )
          : null,
      startDate: DateTime.parse(json['startDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.toARGB32(),
      'description': description,
      'frequency': frequency.index,
      'selectedDays': selectedDays,
      'weeklyTarget': weeklyTarget,
      'hasReminder': hasReminder,
      'reminderHour': reminderTime?.hour,
      'reminderMinute': reminderTime?.minute,
      'startDate': startDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isArchived': isArchived,
      'sortOrder': sortOrder,
    };
  }
}
