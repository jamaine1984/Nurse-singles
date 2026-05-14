import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/user_model.dart';

final safetyServiceProvider = Provider<SafetyService>((ref) {
  return SafetyService();
});

class SafetyService {
  SafetyService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  Future<void> reportUser({
    required UserModel reporter,
    required String reportedUserId,
    required String reportedUserName,
    required ReportReason reason,
    required String reasonLabel,
    required String source,
    String? details,
    String? chatId,
    String? messageId,
  }) async {
    final cleanedDetails = details?.trim();
    await _firestore.collection(AppConstants.reportsCollection).add({
      'reporterId': reporter.id,
      'reporterUserId': reporter.id,
      'reporterName': reporter.name,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'reason': reason.value,
      'reasonLabel': reasonLabel,
      'details': cleanedDetails?.isEmpty == true ? null : cleanedDetails,
      'source': source,
      'chatId': chatId,
      'messageId': messageId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    if (currentUserId == blockedUserId) return;

    final callable = _functions.httpsCallable('blockUser');
    await callable.call<Map<String, dynamic>>({
      'userId': currentUserId,
      'blockedUserId': blockedUserId,
    });
  }

  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    final callable = _functions.httpsCallable('unblockUser');
    await callable.call<Map<String, dynamic>>({
      'userId': currentUserId,
      'blockedUserId': blockedUserId,
    });
  }

  Future<List<UserModel>> fetchUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    final users = <UserModel>[];
    for (var i = 0; i < userIds.length; i += 10) {
      final chunk = userIds.skip(i).take(10).toList();
      final snapshot = await _usersRef
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(snapshot.docs.map(UserModel.fromFirestore));
    }

    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  Future<bool> isBlockedBetween(String userId, String otherUserId) async {
    final docs = await Future.wait([
      _usersRef.doc(userId).get(),
      _usersRef.doc(otherUserId).get(),
    ]);
    if (!docs[0].exists || !docs[1].exists) return true;
    final user = UserModel.fromFirestore(docs[0]);
    final other = UserModel.fromFirestore(docs[1]);
    return user.blocked.contains(otherUserId) || other.blocked.contains(userId);
  }
}
