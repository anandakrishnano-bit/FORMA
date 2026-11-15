import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────── Firebase Instance Providers ───────────────────────

/// Provides access to the [FirebaseAuth] singleton.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides access to the [FirebaseFirestore] singleton.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ─────────────────────── Auth State ───────────────────────────────────────

/// A stream of [User?] that emits whenever the authentication state changes
/// (sign-in, sign-out, token refresh).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Returns the current [User] synchronously if already authenticated.
final currentFirebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).currentUser;
});

// ─────────────────────── User Model ──────────────────────────────────────

/// Minimal user model for FORMA.
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final bool onboardingComplete;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? trainingPreferences;
  final List<String>? habits;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bio,
    this.onboardingComplete = false,
    this.preferences,
    this.trainingPreferences,
    this.habits,
    required this.createdAt,
  });

  String? get photoURL => photoUrl;
  String? get avatarUrl => photoUrl;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: (data['displayName'] ?? data['name']) as String? ?? '',
      photoUrl: (data['photoURL'] ?? data['photoUrl'] ?? data['avatarUrl'])
          as String?,
      bio: data['bio'] as String?,
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
      preferences: data['preferences'] as Map<String, dynamic>?,
      trainingPreferences: data['trainingPreferences'] as Map<String, dynamic>?,
      habits: (data['habits'] as List<dynamic>?)?.cast<String>(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'photoURL': photoUrl,
      'avatarUrl': photoUrl,
      'bio': bio,
      'onboardingComplete': onboardingComplete,
      'preferences': preferences,
      'trainingPreferences': trainingPreferences,
      'habits': habits,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    bool? onboardingComplete,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? trainingPreferences,
    List<String>? habits,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      preferences: preferences ?? this.preferences,
      trainingPreferences: trainingPreferences ?? this.trainingPreferences,
      habits: habits ?? this.habits,
      createdAt: createdAt,
    );
  }
}

// ─────────────────────── Current User from Firestore ─────────────────────

/// Fetches the current user's [UserModel] from Firestore.
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return null;

  final doc = await ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});

/// Live reactive stream of the currently authenticated user's [UserModel] from Firestore.
final currentUserProfileStreamProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull ??
      ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value(null);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  });
});

// ─────────────────────── Auth Repository ─────────────────────────────────

/// Repository that encapsulates all authentication operations.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  /// Creates a new user with email and password, then writes
  /// an initial Firestore document.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    // Write initial user document
    final userModel = UserModel(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      onboardingComplete: false,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(userModel.toMap());

    return credential;
  }

  /// Signs in an existing user with email and password.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sends a password reset email.
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Updates the user profile in Firestore.
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// Marks onboarding as complete in Firestore.
  Future<void> completeOnboarding(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'onboardingComplete': true,
    });
  }
}

/// Provides the [AuthRepository] instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

// ─────────────────────── Convenience Action Providers ─────────────────────

/// Provider for sign-up action. Returns the [UserCredential] on success.
final signUpProvider =
    FutureProvider.family<UserCredential, SignUpParams>((ref, params) async {
  return ref.read(authRepositoryProvider).signUp(
        email: params.email,
        password: params.password,
        displayName: params.displayName,
      );
});

/// Provider for sign-in action.
final signInProvider =
    FutureProvider.family<UserCredential, SignInParams>((ref, params) async {
  return ref.read(authRepositoryProvider).signIn(
        email: params.email,
        password: params.password,
      );
});

/// Provider for sign-out action.
final signOutProvider = FutureProvider<void>((ref) async {
  return ref.read(authRepositoryProvider).signOut();
});

/// Checks whether the current user has completed onboarding.
final isOnboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return false;

  final doc = await ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) return false;
  return (doc.data()?['onboardingComplete'] as bool?) ?? false;
});

// ─────────────────────── Parameter Classes ────────────────────────────────

class SignUpParams {
  final String email;
  final String password;
  final String displayName;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

class SignInParams {
  final String email;
  final String password;

  const SignInParams({
    required this.email,
    required this.password,
  });
}
