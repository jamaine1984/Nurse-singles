import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides the singleton [SocialService].
final socialServiceProvider = Provider<SocialService>((ref) {
  return SocialService();
});

// ---------------------------------------------------------------------------
// PostModel
// ---------------------------------------------------------------------------

/// Data model for a community post stored in the `posts` collection.
class PostModel {
  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    this.imageUrl,
    this.channelId = 'break_room',
    this.channelLabel = 'Break Room',
    this.likes = const [],
    this.comments = const [],
    this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final String? imageUrl;
  final String channelId;
  final String channelLabel;
  final List<String> likes;
  final List<Map<String, dynamic>> comments;
  final DateTime? createdAt;

  // ---- Firestore serialisation -------------------------------------------

  factory PostModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PostModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      channelId: data['channelId'] as String? ?? 'break_room',
      channelLabel: data['channelLabel'] as String? ?? 'Break Room',
      likes: _toStringList(data['likes']),
      comments: _toCommentList(data['comments']),
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'content': content,
    'imageUrl': imageUrl,
    'channelId': channelId,
    'channelLabel': channelLabel,
    'likes': likes,
    'comments': comments,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };

  // ---- Convenience -------------------------------------------------------

  bool isLikedBy(String userId) => likes.contains(userId);
  int get likeCount => likes.length;
  int get commentCount => comments.length;

  // ---- Helpers -----------------------------------------------------------

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static List<Map<String, dynamic>> _toCommentList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

// ---------------------------------------------------------------------------
// SocialService
// ---------------------------------------------------------------------------

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection(AppConstants.postsCollection);

  // ---- Read --------------------------------------------------------------

  /// Streams the latest 20 posts ordered by creation time (newest first).
  Stream<List<PostModel>> getPosts({String? channelId}) {
    Query<Map<String, dynamic>> query = _postsRef;
    if (channelId != null && channelId != 'all') {
      query = query.where('channelId', isEqualTo: channelId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.paginationLimit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Loads the next page of posts older than [lastCreatedAt].
  Future<List<PostModel>> getMorePosts(DateTime lastCreatedAt) async {
    final snapshot = await _postsRef
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(lastCreatedAt)])
        .limit(AppConstants.paginationLimit)
        .get();

    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  // ---- Write -------------------------------------------------------------

  /// Creates a new post in the `posts` collection.
  Future<void> createPost({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
    String? imageUrl,
    String channelId = 'break_room',
    String channelLabel = 'Break Room',
  }) async {
    await _postsRef.add({
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrl': imageUrl,
      'channelId': channelId,
      'channelLabel': channelLabel,
      'likes': <String>[],
      'comments': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[SocialService] Post created by $userId');
  }

  // ---- Likes -------------------------------------------------------------

  /// Toggles a like on a post.
  ///
  /// If [userId] is already in the `likes` array it is removed; otherwise it is
  /// added.
  Future<void> likePost(String postId, String userId) async {
    final docRef = _postsRef.doc(postId);

    await _firestore.runTransaction((txn) async {
      final snapshot = await txn.get(docRef);
      if (!snapshot.exists) return;

      final currentLikes = PostModel._toStringList(snapshot.data()?['likes']);

      if (currentLikes.contains(userId)) {
        txn.update(docRef, {
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        txn.update(docRef, {
          'likes': FieldValue.arrayUnion([userId]),
        });
      }
    });
  }

  // ---- Comments ----------------------------------------------------------

  /// Adds a comment to a post.
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String comment,
  }) async {
    final commentData = {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'comment': comment,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _postsRef.doc(postId).update({
      'comments': FieldValue.arrayUnion([commentData]),
    });
    debugPrint('[SocialService] Comment added to $postId by $userId');
  }

  // ---- Delete ------------------------------------------------------------

  /// Deletes a post by its [postId].
  Future<void> deletePost(String postId) async {
    await _postsRef.doc(postId).delete();
    debugPrint('[SocialService] Post $postId deleted');
  }
}
