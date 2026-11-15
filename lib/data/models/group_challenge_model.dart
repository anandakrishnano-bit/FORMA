class GroupMember {
  final String userId;
  final String displayName;
  final String role; // 'admin' or 'member'
  final DateTime joinedAt;
  final int points;
  final Map<String, bool>
      sharingPreferences; // 'workout', 'habits', 'nutrition', 'profile'

  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.points = 0,
    this.sharingPreferences = const {
      'workout': true,
      'habits': true,
      'nutrition': false,
      'profile': true,
    },
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'points': points,
      'sharingPreferences': sharingPreferences,
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'Friend',
      role: map['role'] ?? 'member',
      joinedAt:
          DateTime.parse(map['joinedAt'] ?? DateTime.now().toIso8601String()),
      points: map['points'] ?? 0,
      sharingPreferences:
          Map<String, bool>.from(map['sharingPreferences'] ?? {}),
    );
  }
}

class GroupChallenge {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String metric; // 'workouts' or 'habit_streaks'
  final int targetValue;
  final DateTime endDate;
  final Map<String, int> participantScores; // userId -> score

  const GroupChallenge({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.metric,
    required this.targetValue,
    required this.endDate,
    required this.participantScores,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'metric': metric,
      'targetValue': targetValue,
      'endDate': endDate.toIso8601String(),
      'participantScores': participantScores,
    };
  }

  factory GroupChallenge.fromMap(Map<String, dynamic> map) {
    return GroupChallenge(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      metric: map['metric'] ?? 'workouts',
      targetValue: map['targetValue'] ?? 0,
      endDate:
          DateTime.parse(map['endDate'] ?? DateTime.now().toIso8601String()),
      participantScores: Map<String, int>.from(map['participantScores'] ?? {}),
    );
  }
}
