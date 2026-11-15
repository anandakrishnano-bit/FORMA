/// A friend's recent activity for the social feed.
class FriendActivity {
  final String id;
  final String friendName;
  final String? friendAvatarUrl;
  final String action;
  final DateTime timestamp;

  const FriendActivity({
    required this.id,
    required this.friendName,
    this.friendAvatarUrl,
    required this.action,
    required this.timestamp,
  });

  /// Human-readable relative time string.
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  factory FriendActivity.fromJson(Map<String, dynamic> json) {
    return FriendActivity(
      id: json['id'] as String,
      friendName: json['friendName'] as String,
      friendAvatarUrl: json['friendAvatarUrl'] as String?,
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friendName': friendName,
      'friendAvatarUrl': friendAvatarUrl,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
