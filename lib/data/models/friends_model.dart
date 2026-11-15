import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, declined, cancelled }

/// Genuine, authenticated FORMA user representation for friends & social features.
///
/// ZERO FAKE DATA GUARANTEE:
/// Strict privacy controls: Never includes email, phone number, private expenses, or nutrition logs.
class FriendUser {
  final String uid;
  final String displayName;
  final String username;
  final String friendCode;
  final String? avatarUrl;
  final String? photoUrl;
  final String? bio;
  final DateTime? joinedAt;
  final bool shareWorkouts;
  final bool shareHabits;
  final bool isOnline;

  const FriendUser({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.friendCode,
    this.avatarUrl,
    this.photoUrl,
    this.bio,
    this.joinedAt,
    this.shareWorkouts = true,
    this.shareHabits = false,
    this.isOnline = false,
  });

  factory FriendUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendUser.fromMap(doc.id, data);
  }

  factory FriendUser.fromMap(String id, Map<String, dynamic> data) {
    final resolvedAvatar =
        (data['photoURL'] ?? data['photoUrl'] ?? data['avatarUrl']) as String?;
    return FriendUser(
      uid: id,
      displayName: data['displayName'] as String? ?? 'Athlete',
      username: data['username'] as String? ?? '',
      friendCode: data['friendCode'] as String? ?? '',
      avatarUrl: resolvedAvatar,
      photoUrl: resolvedAvatar,
      bio: data['bio'] as String?,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate(),
      shareWorkouts: data['shareWorkouts'] as bool? ?? true,
      shareHabits: data['shareHabits'] as bool? ?? false,
      isOnline: data['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'username': username,
      'friendCode': friendCode,
      'avatarUrl': avatarUrl,
      'photoUrl': photoUrl,
      'bio': bio,
      'joinedAt': joinedAt != null
          ? Timestamp.fromDate(joinedAt!)
          : FieldValue.serverTimestamp(),
      'shareWorkouts': shareWorkouts,
      'shareHabits': shareHabits,
    };
  }
}

/// Real friend invitation record between two registered users.
class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String senderUsername;
  final String? senderAvatarUrl;
  final String receiverId;
  final String receiverName;
  final String receiverUsername;
  final String? receiverAvatarUrl;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderUsername,
    this.senderAvatarUrl,
    required this.receiverId,
    required this.receiverName,
    required this.receiverUsername,
    this.receiverAvatarUrl,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendRequest(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Athlete',
      senderUsername: data['senderUsername'] as String? ?? '',
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
      receiverId: data['receiverId'] as String? ?? '',
      receiverName: data['receiverName'] as String? ?? 'Athlete',
      receiverUsername: data['receiverUsername'] as String? ?? '',
      receiverAvatarUrl: data['receiverAvatarUrl'] as String?,
      status: _statusFromString(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static FriendRequestStatus _statusFromString(String str) {
    switch (str.toLowerCase()) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'declined':
        return FriendRequestStatus.declined;
      case 'cancelled':
        return FriendRequestStatus.cancelled;
      default:
        return FriendRequestStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderUsername': senderUsername,
      'senderAvatarUrl': senderAvatarUrl,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverUsername': receiverUsername,
      'receiverAvatarUrl': receiverAvatarUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Private group model with admin roles and join codes.
class SocialGroup {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> adminIds;
  final List<String> memberIds;
  final String joinCode;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isPrivate;

  const SocialGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.adminIds,
    required this.memberIds,
    required this.joinCode,
    this.avatarUrl,
    required this.createdAt,
    this.isPrivate = true,
  });

  factory SocialGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SocialGroup(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Group',
      description: data['description'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      adminIds: (data['adminIds'] as List<dynamic>?)?.cast<String>() ?? [],
      memberIds: (data['memberIds'] as List<dynamic>?)?.cast<String>() ?? [],
      joinCode: data['joinCode'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPrivate: data['isPrivate'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'joinCode': joinCode,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrivate': isPrivate,
    };
  }
}

/// Member within a private group.
class SocialGroupMember {
  final String userId;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String role; // 'owner', 'admin', 'member'
  final DateTime joinedAt;

  const SocialGroupMember({
    required this.userId,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory SocialGroupMember.fromMap(Map<String, dynamic> data) {
    return SocialGroupMember(
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Member',
      username: data['username'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      role: data['role'] as String? ?? 'member',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'username': username,
      'avatarUrl': avatarUrl,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

/// Factual social milestone item for activity feed.
class SocialActivityItem {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String type; // 'workout_completed', 'habit_milestone'
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const SocialActivityItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
  });

  factory SocialActivityItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SocialActivityItem(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Athlete',
      userAvatarUrl: data['userAvatarUrl'] as String?,
      type: data['type'] as String? ?? 'workout_completed',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'type': type,
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
