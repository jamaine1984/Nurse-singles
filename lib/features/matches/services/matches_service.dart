import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

/// Provides a singleton [MatchesService] via Riverpod.
final matchesServiceProvider = Provider<MatchesService>((ref) {
  return MatchesService(FirebaseFirestore.instance);
});

// ─── MatchModel ─────────────────────────────────────────────────────────────

/// Data model for a mutual match between two users.
class MatchModel {
  const MatchModel({
    required this.id,
    required this.users,
    required this.user1,
    required this.user2,
    required this.user1Name,
    required this.user2Name,
    required this.user1Photo,
    required this.user2Photo,
    this.createdAt,
    this.lastInteraction,
  });

  final String id;
  final List<String> users;
  final String user1;
  final String user2;
  final String user1Name;
  final String user2Name;
  final String user1Photo;
  final String user2Photo;
  final DateTime? createdAt;
  final DateTime? lastInteraction;

  factory MatchModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MatchModel(
      id: doc.id,
      users: List<String>.from(data['users'] ?? []),
      user1: data['user1'] as String? ?? '',
      user2: data['user2'] as String? ?? '',
      user1Name: data['user1Name'] as String? ?? '',
      user2Name: data['user2Name'] as String? ?? '',
      user1Photo: data['user1Photo'] as String? ?? '',
      user2Photo: data['user2Photo'] as String? ?? '',
      createdAt: _toDateTime(data['createdAt']),
      lastInteraction: _toDateTime(data['lastInteraction']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'users': users,
      'user1': user1,
      'user2': user2,
      'user1Name': user1Name,
      'user2Name': user2Name,
      'user1Photo': user1Photo,
      'user2Photo': user2Photo,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastInteraction': lastInteraction != null
          ? Timestamp.fromDate(lastInteraction!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Returns the other user's ID relative to [myUserId].
  String otherUserId(String myUserId) => user1 == myUserId ? user2 : user1;

  /// Returns the other user's display name relative to [myUserId].
  String otherUserName(String myUserId) =>
      user1 == myUserId ? user2Name : user1Name;

  /// Returns the other user's photo URL relative to [myUserId].
  String otherUserPhoto(String myUserId) =>
      user1 == myUserId ? user2Photo : user1Photo;

  /// Whether this match was created within the last 24 hours.
  bool get isNew {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt!).inHours < 24;
  }

  /// Whether this match was created within the last 7 days.
  bool get isRecent {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt!).inDays < 7;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  String toString() => 'MatchModel(id: $id, users: $users)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MatchModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ─── MatchesService ─────────────────────────────────────────────────────────

class MatchesService {
  MatchesService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Streams all matches for [userId], newest first.
  Stream<List<MatchModel>> getMatches(String userId) {
    return _firestore
        .collection(AppConstants.matchesCollection)
        .where('users', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final matches = snapshot.docs
              .map((doc) => MatchModel.fromFirestore(doc))
              .toList();
          matches.sort((a, b) => _compareDateDesc(a.createdAt, b.createdAt));
          return matches;
        });
  }

  /// Streams matches from the last 7 days for [userId].
  Stream<List<MatchModel>> getRecentMatches(String userId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _firestore
        .collection(AppConstants.matchesCollection)
        .where('users', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final matches = snapshot.docs
              .map((doc) => MatchModel.fromFirestore(doc))
              .where(
                (match) =>
                    match.createdAt != null &&
                    !match.createdAt!.isBefore(sevenDaysAgo),
              )
              .toList();
          matches.sort((a, b) => _compareDateDesc(a.createdAt, b.createdAt));
          return matches;
        });
  }

  /// Deletes a match and its related likes.
  Future<void> unmatch(String matchId) async {
    // Fetch the match document first so we can clean up likes.
    final matchDoc = await _firestore
        .collection(AppConstants.matchesCollection)
        .doc(matchId)
        .get();

    if (!matchDoc.exists) return;

    final data = matchDoc.data()!;
    final user1 = data['user1'] as String;
    final user2 = data['user2'] as String;

    final batch = _firestore.batch();

    // Delete the match document.
    batch.delete(matchDoc.reference);

    // Find and delete related like docs in both directions.
    final likes1 = await _firestore
        .collection(AppConstants.likesCollection)
        .where('likerId', isEqualTo: user1)
        .where('likedUserId', isEqualTo: user2)
        .get();

    for (final doc in likes1.docs) {
      batch.delete(doc.reference);
    }

    final likes2 = await _firestore
        .collection(AppConstants.likesCollection)
        .where('likerId', isEqualTo: user2)
        .where('likedUserId', isEqualTo: user1)
        .get();

    for (final doc in likes2.docs) {
      batch.delete(doc.reference);
    }

    // Decrement match stats for both users.
    batch.update(
      _firestore.collection(AppConstants.usersCollection).doc(user1),
      {'stats.matches': FieldValue.increment(-1)},
    );
    batch.update(
      _firestore.collection(AppConstants.usersCollection).doc(user2),
      {'stats.matches': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  static int _compareDateDesc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
