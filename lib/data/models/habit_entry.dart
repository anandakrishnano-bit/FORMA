/// A single completion entry for a habit on a specific date.
class HabitEntry {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final String? note;
  final DateTime createdAt;

  const HabitEntry({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    this.note,
    required this.createdAt,
  });

  HabitEntry copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    bool? completed,
    String? note,
    DateTime? createdAt,
  }) {
    return HabitEntry(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory HabitEntry.fromJson(Map<String, dynamic> json) {
    return HabitEntry(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      date: DateTime.parse(json['date'] as String),
      completed: json['completed'] as bool,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date.toIso8601String(),
      'completed': completed,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
