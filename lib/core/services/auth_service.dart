import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/user_model.dart';

/// Provides the singleton [AuthService] instance through Riverpod.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

/// Firebase Authentication service that also manages the corresponding
/// Firestore user document in the `users` collection.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ─── Streams ─────────────────────────────────────────────────────────

  /// Emits the current [User] whenever the auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in [User], or `null`.
  User? get currentUser => _auth.currentUser;

  /// Convenience getter for the current user's UID.
  String? get currentUserId => _auth.currentUser?.uid;

  // ─── Sign Up ─────────────────────────────────────────────────────────

  /// Creates a new Firebase Auth account **and** a matching Firestore user
  /// document with sensible defaults.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Account creation succeeded but no user was returned.',
      );
    }

    // Update the display name on the Auth profile
    await user.updateDisplayName(name.trim());

    final now = DateTime.now();
    final userModel = UserModel(
      id: user.uid,
      name: name.trim(),
      email: email.trim(),
      plan: SubscriptionPlan.free,
      videoMinutes: AppConstants.defaultVideoMinutes,
      messagesLeft: AppConstants.defaultMessagesPerDay,
      giftPoints: AppConstants.defaultGiftPoints,
      superlikesLeft: AppConstants.defaultSuperlikesPerDay,
      isOnline: true,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toFirestore());

    return userModel;
  }

  // ─── Sign In ─────────────────────────────────────────────────────────

  /// Signs in with email + password and marks the user as online.
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    // Mark online
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update({'isOnline': true, 'lastSeen': FieldValue.serverTimestamp()});

    return getCurrentUser();
  }

  // ─── Sign Out ────────────────────────────────────────────────────────

  /// Marks the user as offline and signs out of Firebase Auth.
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'isOnline': false, 'lastSeen': FieldValue.serverTimestamp()},
      );
    }
    await _auth.signOut();
  }

  // ─── Password Reset ─────────────────────────────────────────────────

  /// Sends a password-reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── Get Current User ────────────────────────────────────────────────

  /// Fetches the full [UserModel] for the currently signed-in user.
  Future<UserModel?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists || doc.data() == null) return null;

    return UserModel.fromFirestore(doc);
  }

  /// Alias matching the previous API surface used by providers.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Returns a real-time stream of the current user's [UserModel].
  Stream<UserModel?> streamCurrentUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return UserModel.fromFirestore(doc);
        });
  }

  // ─── Update Profile ──────────────────────────────────────────────────

  /// Merges the provided [fields] into the current user's Firestore document.
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user');

    fields['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(fields);
  }

  /// Alias matching the previous API surface.
  Future<void> updateUserProfile(Map<String, dynamic> data) =>
      updateProfile(data);

  /// Sets the full user profile (merge).
  Future<void> setUserProfile(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  // ─── Delete Account ──────────────────────────────────────────────────

  /// Deletes the Firestore user document **and** the Firebase Auth account.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user');

    // Remove Firestore document first
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .delete();

    // Then delete the auth account
    await user.delete();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  /// Fetches any user's profile by [userId].
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Streams any user's profile by [userId].
  Stream<UserModel?> streamUserById(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return UserModel.fromFirestore(doc);
        });
  }
}
