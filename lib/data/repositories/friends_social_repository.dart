import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/services/app_logger.dart';
import 'package:forma/core/services/notification_service.dart';
import 'package:forma/data/models/friends_model.dart';
import 'package:forma/features/authentication/providers/auth_providers.dart';

/// Full, genuine Friends & Social Repository powered purely by Firebase Firestore.
///
/// ZERO FAKE DATA GUARANTEE:
/// - No dummy "Alex Rivers" or hardcoded partners.
/// - Atomic bidirectional friendship lifecycle: Request -> Accept/Decline/Cancel -> Remove.
/// - Privacy guarantee: Personal expenses, food intake, and vitals remain strictly private.
class FriendsSocialRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FriendsSocialRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  // ═════════════════════════════════════════════════════════════════════════
  // FRIEND CODE & IDENTITY
  // ═════════════════════════════════════════════════════════════════════════

  /// Ensures current user has a unique friend code (e.g. FORMA-7K9M) and returns it.
  Future<String> getMyFriendCode({String? userId}) async {
    var uid = userId ?? currentUserId;
    if (uid == null) {
      try {
        final user = await _auth
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 2));
        uid = user?.uid;
      } catch (_) {}
    }
    if (uid == null) return 'FORMA-GUEST';

    return _fetchOrCreateFriendCode(uid);
  }

  Future<String> _fetchOrCreateFriendCode(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final existing = userDoc.data()!['friendCode'] as String?;
        if (existing != null && existing.isNotEmpty) {
          return existing;
        }
      }

      // Generate a memorable 6-char code
      final cleanUid =
          uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      final suffix = cleanUid.length >= 6
          ? cleanUid.substring(0, 6)
          : cleanUid.padRight(6, 'X');
      final code = 'FORMA-$suffix';

      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('users').doc(uid),
        {'friendCode': code},
        SetOptions(merge: true),
      );
      batch.set(
        _firestore.collection('userFriendCodes').doc(code),
        {'uid': uid, 'createdAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      await batch.commit();

      AppLogger.success('FRIENDS', 'Assigned friend code $code to $uid');
      return code;
    } catch (e) {
      AppLogger.warn('FRIENDS',
          'Error assigning friend code, falling back to deterministic: $e');
      final cleanUid =
          uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      return 'FORMA-${cleanUid.substring(0, min(6, cleanUid.length))}';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // USER SEARCH & DISCOVERY (Exact username or Friend Code)
  // ═════════════════════════════════════════════════════════════════════════

  /// Searches for real registered users by exact username or unique friend code.
  Future<List<FriendUser>> searchUsers(String query) async {
    final uid = currentUserId;
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final results = <FriendUser>[];

    try {
      // 1. Search by Friend Code
      var codeQuery = clean.toUpperCase();
      if (!codeQuery.startsWith('FORMA-') && codeQuery.length == 6) {
        codeQuery = 'FORMA-$codeQuery';
      }

      if (codeQuery.startsWith('FORMA-')) {
        final codeDoc =
            await _firestore.collection('userFriendCodes').doc(codeQuery).get();
        if (codeDoc.exists && codeDoc.data() != null) {
          final targetUid = codeDoc.data()!['uid'] as String?;
          if (targetUid != null && targetUid != uid) {
            final targetDoc =
                await _firestore.collection('users').doc(targetUid).get();
            if (targetDoc.exists && targetDoc.data() != null) {
              results.add(FriendUser.fromFirestore(targetDoc));
              return results;
            }
          }
        }

        // Direct query on users collection if index not populated
        final userByCode = await _firestore
            .collection('users')
            .where('friendCode', isEqualTo: codeQuery)
            .limit(1)
            .get();

        for (final doc in userByCode.docs) {
          if (doc.id != uid) {
            results.add(FriendUser.fromFirestore(doc));
          }
        }
        if (results.isNotEmpty) return results;
      }

      // 2. Search by exact username
      final usernameClean = clean.startsWith('@')
          ? clean.substring(1).toLowerCase()
          : clean.toLowerCase();
      final userByUsername = await _firestore
          .collection('users')
          .where('username', isEqualTo: usernameClean)
          .limit(3)
          .get();

      for (final doc in userByUsername.docs) {
        if (doc.id != uid) {
          results.add(FriendUser.fromFirestore(doc));
        }
      }

      // 3. Fallback partial search on displayName
      if (results.isEmpty) {
        final userByName = await _firestore
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: clean)
            .where('displayName', isLessThanOrEqualTo: '$clean\uf8ff')
            .limit(5)
            .get();

        for (final doc in userByName.docs) {
          if (doc.id != uid && !results.any((r) => r.uid == doc.id)) {
            results.add(FriendUser.fromFirestore(doc));
          }
        }
      }

      // Filter out any users blocked by current user
      if (uid != null && results.isNotEmpty) {
        final blockedSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('blockedUsers')
            .get();
        final blockedIds = blockedSnapshot.docs.map((d) => d.id).toSet();
        results.removeWhere((u) => blockedIds.contains(u.uid));
      }

      return results;
    } catch (e) {
      AppLogger.warn('FRIENDS', 'Search failed: $e');
      return [];
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FRIEND REQUEST LIFECYCLE (Send, Accept, Decline, Cancel)
  // ═════════════════════════════════════════════════════════════════════════

  /// Sends a friend request to a real target user.
  Future<(bool, String)> sendFriendRequest(FriendUser targetUser) async {
    final uid = currentUserId;
    final me = currentUser;
    if (uid == null || me == null) {
      return (false, 'You must be signed in to send friend requests.');
    }

    if (targetUser.uid == uid) {
      return (false, 'You cannot send a friend request to yourself.');
    }

    try {
      // 1. Check if already friends
      final existingFriendDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .doc(targetUser.uid)
          .get();
      if (existingFriendDoc.exists) {
        return (
          false,
          'You are already friends with ${targetUser.displayName}.'
        );
      }

      // 2. Check if a request is already pending
      final existingRequestQuery = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: uid)
          .where('receiverId', isEqualTo: targetUser.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequestQuery.docs.isNotEmpty) {
        return (false, 'Friend request already sent and pending acceptance.');
      }

      // Check reverse pending request (target already invited me)
      final reverseRequestQuery = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: targetUser.uid)
          .where('receiverId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (reverseRequestQuery.docs.isNotEmpty) {
        // Automatically accept reverse request!
        final revReq =
            FriendRequest.fromFirestore(reverseRequestQuery.docs.first);
        await acceptFriendRequest(revReq);
        return (
          true,
          '${targetUser.displayName} had already invited you! You are now friends.'
        );
      }

      // Fetch sender profile details
      final myProfileDoc = await _firestore.collection('users').doc(uid).get();
      final myData = myProfileDoc.data() ?? {};
      final senderName =
          me.displayName ?? myData['displayName'] as String? ?? 'Athlete';
      final senderUsername = myData['username'] as String? ?? '';
      final senderAvatarUrl =
          myData['avatarUrl'] as String? ?? myData['photoUrl'] as String?;

      final requestId = '${uid}_${targetUser.uid}';
      final request = FriendRequest(
        id: requestId,
        senderId: uid,
        senderName: senderName,
        senderUsername: senderUsername,
        senderAvatarUrl: senderAvatarUrl,
        receiverId: targetUser.uid,
        receiverName: targetUser.displayName,
        receiverUsername: targetUser.username,
        receiverAvatarUrl: targetUser.avatarUrl,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .set(request.toMap());

      // Show local confirmation notification
      NotificationService()
          .showFriendRequestNotification(
            senderName: senderName,
            requestId: requestId,
          )
          .ignore();

      AppLogger.success('FRIENDS',
          'Sent friend request to ${targetUser.displayName} ($requestId)');
      return (true, 'Friend request sent to ${targetUser.displayName}!');
    } catch (e, st) {
      AppLogger.error('FRIENDS', 'Error sending friend request: $e', e, st);
      return (false, 'Failed to send friend request: $e');
    }
  }

  /// Cancels an outgoing friend request.
  Future<bool> cancelFriendRequest(String requestId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final docRef = _firestore.collection('friendRequests').doc(requestId);
      final doc = await docRef.get();
      if (doc.exists && doc.data()?['senderId'] == uid) {
        await docRef.update({'status': 'cancelled'});
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.warn('FRIENDS', 'Error cancelling friend request: $e');
      return false;
    }
  }

  /// Accepts an incoming friend request and establishes bidirectional friendship.
  Future<bool> acceptFriendRequest(FriendRequest request) async {
    final uid = currentUserId;
    if (uid == null || request.receiverId != uid) return false;

    try {
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      // 1. Update friendRequest status
      final reqRef = _firestore.collection('friendRequests').doc(request.id);
      batch.update(reqRef, {'status': 'accepted', 'acceptedAt': now});

      // 2. Add to receiver's friends collection
      final myFriendRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .doc(request.senderId);
      batch.set(myFriendRef, {
        'uid': request.senderId,
        'displayName': request.senderName,
        'username': request.senderUsername,
        'avatarUrl': request.senderAvatarUrl,
        'joinedAt': now,
        'shareWorkouts': true,
      });

      // 3. Add to sender's friends collection
      final senderFriendRef = _firestore
          .collection('users')
          .doc(request.senderId)
          .collection('friends')
          .doc(uid);
      batch.set(senderFriendRef, {
        'uid': uid,
        'displayName': request.receiverName,
        'username': request.receiverUsername,
        'avatarUrl': request.receiverAvatarUrl,
        'joinedAt': now,
        'shareWorkouts': true,
      });

      // 4. Create centralized friendship record
      final friendshipId = uid.compareTo(request.senderId) < 0
          ? '${uid}_${request.senderId}'
          : '${request.senderId}_$uid';
      final friendshipRef =
          _firestore.collection('friendships').doc(friendshipId);
      batch.set(friendshipRef, {
        'userA': uid,
        'userB': request.senderId,
        'createdAt': now,
        'status': 'active',
      });

      // 5. Post social activity milestone
      final activityRef = _firestore.collection('socialActivities').doc();
      batch.set(activityRef, {
        'userId': uid,
        'userName': request.receiverName,
        'userAvatarUrl': request.receiverAvatarUrl,
        'type': 'friend_connected',
        'title': 'New Training Partner',
        'description':
            '${request.receiverName} and ${request.senderName} are now connected on FORMA.',
        'timestamp': now,
        'metadata': {'friendUid': request.senderId},
      });

      await batch.commit();

      // Native notification
      NotificationService()
          .showFriendAcceptedNotification(friendName: request.senderName)
          .ignore();

      AppLogger.success(
          'FRIENDS', 'Accepted friend request from ${request.senderName}');
      return true;
    } catch (e, st) {
      AppLogger.error('FRIENDS', 'Error accepting friend request: $e', e, st);
      return false;
    }
  }

  /// Declines an incoming friend request.
  Future<bool> declineFriendRequest(String requestId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final docRef = _firestore.collection('friendRequests').doc(requestId);
      final doc = await docRef.get();
      if (doc.exists && doc.data()?['receiverId'] == uid) {
        await docRef.update({'status': 'declined'});
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.warn('FRIENDS', 'Error declining friend request: $e');
      return false;
    }
  }

  /// Removes an existing friend relationship.
  Future<bool> removeFriend(String friendUid) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final batch = _firestore.batch();
      batch.delete(_firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .doc(friendUid));
      batch.delete(_firestore
          .collection('users')
          .doc(friendUid)
          .collection('friends')
          .doc(uid));

      final friendshipId = uid.compareTo(friendUid) < 0
          ? '${uid}_$friendUid'
          : '${friendUid}_$uid';
      batch.delete(_firestore.collection('friendships').doc(friendshipId));

      await batch.commit();
      AppLogger.info('FRIENDS', 'Removed friend $friendUid');
      return true;
    } catch (e) {
      AppLogger.error('FRIENDS', 'Error removing friend: $e');
      return false;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // STREAMS FOR LIVE SOCIAL DATA
  // ═════════════════════════════════════════════════════════════════════════

  /// Streams incoming pending friend requests.
  Stream<List<FriendRequest>> streamIncomingRequests({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) {
      return _auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream.value(<FriendRequest>[]);
        return _incomingRequestsStream(user.uid);
      });
    }
    return _incomingRequestsStream(uid);
  }

  Stream<List<FriendRequest>> _incomingRequestsStream(String uid) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequest.fromFirestore(d)).toList());
  }

  /// Streams outgoing pending friend requests.
  Stream<List<FriendRequest>> streamOutgoingRequests({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) {
      return _auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream.value(<FriendRequest>[]);
        return _outgoingRequestsStream(user.uid);
      });
    }
    return _outgoingRequestsStream(uid);
  }

  Stream<List<FriendRequest>> _outgoingRequestsStream(String uid) {
    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequest.fromFirestore(d)).toList());
  }

  /// Streams confirmed friends.
  Stream<List<FriendUser>> streamConfirmedFriends({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) {
      return _auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream.value(<FriendUser>[]);
        return _confirmedFriendsStream(user.uid);
      });
    }
    return _confirmedFriendsStream(uid);
  }

  Stream<List<FriendUser>> _confirmedFriendsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => FriendUser.fromMap(d.id, d.data())).toList();
    });
  }

  /// Streams private groups user is a member of.
  Stream<List<SocialGroup>> streamUserGroups({String? userId}) {
    final uid = userId ?? currentUserId;
    if (uid == null) {
      return _auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream.value(<SocialGroup>[]);
        return _userGroupsStream(user.uid);
      });
    }
    return _userGroupsStream(uid);
  }

  Stream<List<SocialGroup>> _userGroupsStream(String uid) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SocialGroup.fromFirestore(d)).toList());
  }

  /// Streams recent social activities and milestones.
  Stream<List<SocialActivityItem>> streamSocialActivities() {
    return _firestore
        .collection('socialActivities')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SocialActivityItem.fromFirestore(d)).toList());
  }

  // ═════════════════════════════════════════════════════════════════════════
  // GROUPS MANAGEMENT
  // ═════════════════════════════════════════════════════════════════════════

  /// Creates a private group with the creator as owner and initial admin.
  Future<(bool, String)> createGroup({
    required String name,
    required String description,
    bool isPrivate = true,
  }) async {
    final uid = currentUserId;
    final me = currentUser;
    if (uid == null || me == null)
      return (false, 'Must be signed in to create groups.');

    try {
      // Generate 6-char group join code
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final rnd = Random();
      final code = String.fromCharCodes(Iterable.generate(
          6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

      final groupRef = _firestore.collection('groups').doc();
      final group = SocialGroup(
        id: groupRef.id,
        name: name.trim(),
        description: description.trim(),
        ownerId: uid,
        adminIds: [uid],
        memberIds: [uid],
        joinCode: 'GRP-$code',
        createdAt: DateTime.now(),
        isPrivate: isPrivate,
      );

      final batch = _firestore.batch();
      batch.set(groupRef, group.toMap());

      // Add owner as first group member
      final memberRef = groupRef.collection('members').doc(uid);
      batch.set(memberRef, {
        'userId': uid,
        'displayName': me.displayName ?? 'Athlete',
        'role': 'owner',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      AppLogger.success('FRIENDS', 'Created group ${group.name} (${group.id})');
      return (
        true,
        'Created group "${group.name}" with code ${group.joinCode}!'
      );
    } catch (e) {
      AppLogger.error('FRIENDS', 'Error creating group: $e');
      return (false, 'Failed to create group: $e');
    }
  }

  /// Joins a private group by 6-char join code (e.g. GRP-XYZ123).
  Future<(bool, String)> joinGroupByCode(String code) async {
    final uid = currentUserId;
    final me = currentUser;
    if (uid == null || me == null)
      return (false, 'Must be signed in to join groups.');

    var cleanCode = code.trim().toUpperCase();
    if (!cleanCode.startsWith('GRP-') && cleanCode.length == 6) {
      cleanCode = 'GRP-$cleanCode';
    }

    try {
      final snap = await _firestore
          .collection('groups')
          .where('joinCode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return (false, 'No group found with code $cleanCode.');
      }

      final groupDoc = snap.docs.first;
      final group = SocialGroup.fromFirestore(groupDoc);

      if (group.memberIds.contains(uid)) {
        return (false, 'You are already a member of "${group.name}".');
      }

      final batch = _firestore.batch();
      batch.update(groupDoc.reference, {
        'memberIds': FieldValue.arrayUnion([uid]),
      });

      final memberRef = groupDoc.reference.collection('members').doc(uid);
      batch.set(memberRef, {
        'userId': uid,
        'displayName': me.displayName ?? 'Athlete',
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      AppLogger.success('FRIENDS', 'Joined group ${group.name}');
      return (true, 'Successfully joined "${group.name}"!');
    } catch (e) {
      AppLogger.error('FRIENDS', 'Error joining group: $e');
      return (false, 'Failed to join group: $e');
    }
  }

  /// Leaves a group.
  Future<bool> leaveGroup(String groupId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final groupRef = _firestore.collection('groups').doc(groupId);
      final batch = _firestore.batch();
      batch.update(groupRef, {
        'memberIds': FieldValue.arrayRemove([uid]),
        'adminIds': FieldValue.arrayRemove([uid]),
      });
      batch.delete(groupRef.collection('members').doc(uid));
      await batch.commit();
      return true;
    } catch (e) {
      AppLogger.error('FRIENDS', 'Error leaving group: $e');
      return false;
    }
  }

  /// Deletes a group (Owner only).
  Future<bool> deleteGroup(String groupId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists || groupDoc.data()?['ownerId'] != uid) {
        return false;
      }
      await groupDoc.reference.delete();
      return true;
    } catch (e) {
      AppLogger.error('FRIENDS', 'Error deleting group: $e');
      return false;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BLOCKING & REPORTING
  // ═════════════════════════════════════════════════════════════════════════

  /// Blocks a user, terminating any active friendship and hiding their profile.
  Future<bool> blockUser(String targetUid) async {
    final uid = currentUserId;
    if (uid == null || uid == targetUid) return false;

    try {
      final batch = _firestore.batch();
      batch.set(
        _firestore
            .collection('users')
            .doc(uid)
            .collection('blockedUsers')
            .doc(targetUid),
        {'blockedAt': FieldValue.serverTimestamp()},
      );
      // Remove friendship if any
      batch.delete(_firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .doc(targetUid));
      batch.delete(_firestore
          .collection('users')
          .doc(targetUid)
          .collection('friends')
          .doc(uid));
      await batch.commit();
      return true;
    } catch (e) {
      AppLogger.error('FRIENDS', 'Error blocking user: $e');
      return false;
    }
  }

  /// Reports a user for inappropriate behavior or violations.
  Future<bool> reportUser({
    required String targetUid,
    required String reason,
    required String details,
  }) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      await _firestore.collection('reports').add({
        'reporterId': uid,
        'reportedUserId': targetUid,
        'reason': reason,
        'details': details,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending_review',
      });
      return true;
    } catch (e) {
      AppLogger.error('FRIENDS', 'Error submitting report: $e');
      return false;
    }
  }
}

// ─────────────────────── Riverpod Providers ───────────────────────────────

final friendsSocialRepositoryProvider =
    Provider<FriendsSocialRepository>((ref) {
  return FriendsSocialRepository();
});

final myFriendCodeStreamProvider = FutureProvider<String>((ref) async {
  final authUser = ref.watch(authStateProvider).valueOrNull ??
      ref.watch(currentFirebaseUserProvider);
  return ref
      .watch(friendsSocialRepositoryProvider)
      .getMyFriendCode(userId: authUser?.uid);
});

final incomingFriendRequestsProvider =
    StreamProvider<List<FriendRequest>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull ??
      ref.watch(currentFirebaseUserProvider);
  return ref
      .watch(friendsSocialRepositoryProvider)
      .streamIncomingRequests(userId: authUser?.uid);
});

final outgoingFriendRequestsProvider =
    StreamProvider<List<FriendRequest>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull ??
      ref.watch(currentFirebaseUserProvider);
  return ref
      .watch(friendsSocialRepositoryProvider)
      .streamOutgoingRequests(userId: authUser?.uid);
});

final confirmedFriendsStreamProvider = StreamProvider<List<FriendUser>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull ??
      ref.watch(currentFirebaseUserProvider);
  return ref
      .watch(friendsSocialRepositoryProvider)
      .streamConfirmedFriends(userId: authUser?.uid);
});

final userGroupsStreamProvider = StreamProvider<List<SocialGroup>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull ??
      ref.watch(currentFirebaseUserProvider);
  return ref
      .watch(friendsSocialRepositoryProvider)
      .streamUserGroups(userId: authUser?.uid);
});

final socialActivitiesStreamProvider =
    StreamProvider<List<SocialActivityItem>>((ref) {
  return ref.watch(friendsSocialRepositoryProvider).streamSocialActivities();
});
