import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

final callNotificationServiceProvider = Provider<CallNotificationService>((
  ref,
) {
  return CallNotificationService();
});

final incomingCallNotificationsProvider = StreamProvider.autoDispose
    .family<List<CallNotification>, String>((ref, userId) {
      return ref
          .watch(callNotificationServiceProvider)
          .watchIncomingCalls(userId);
    });

class CallNotification {
  const CallNotification({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.roomId,
    required this.chatId,
    required this.type,
    required this.status,
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String callerId;
  final String callerName;
  final String receiverId;
  final String roomId;
  final String chatId;
  final String type;
  final String status;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  bool get isRinging => status == 'ringing';
  bool get isTerminal =>
      status == 'declined' || status == 'ended' || status == 'missed';

  bool isFresh(DateTime now) {
    final expiry = expiresAt;
    return expiry == null || expiry.isAfter(now);
  }

  factory CallNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CallNotification(
      id: doc.id,
      callerId: data['callerId'] as String? ?? '',
      callerName: data['callerName'] as String? ?? 'Nurse Singles',
      receiverId: data['receiverId'] as String? ?? '',
      roomId: data['roomId'] as String? ?? '',
      chatId: data['chatId'] as String? ?? '',
      type: data['type'] as String? ?? 'oneOnOne',
      status: data['status'] as String? ?? 'ringing',
      createdAt: _toDateTime(data['createdAt']),
      expiresAt: _toDateTime(data['expiresAt']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class CallNotificationService {
  CallNotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _callsRef =>
      _firestore.collection(AppConstants.callNotificationsCollection);

  String createNotificationId() => _callsRef.doc().id;

  Stream<List<CallNotification>> watchIncomingCalls(String userId) {
    return _callsRef.where('receiverId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final calls = snapshot.docs.map(CallNotification.fromFirestore).toList();

      calls.sort((a, b) {
        final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bCreated.compareTo(aCreated);
      });
      return calls;
    });
  }

  Stream<CallNotification?> watchCall(String notificationId) {
    if (notificationId.isEmpty) return Stream.value(null);
    return _callsRef.doc(notificationId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return CallNotification.fromFirestore(snapshot);
    });
  }

  Future<String> createOneOnOneCallNotification({
    required String notificationId,
    required String callerId,
    required String callerName,
    required String receiverId,
    required String roomId,
    required String chatId,
  }) async {
    final doc = _callsRef.doc(notificationId);
    await doc.set({
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'roomId': roomId,
      'chatId': chatId,
      'type': 'oneOnOne',
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(seconds: 90)),
      ),
    });
    return doc.id;
  }

  Future<void> markAnswered(String notificationId) {
    return tryMarkAnswered(notificationId).then((answered) {
      if (!answered) {
        throw StateError('Call is no longer available');
      }
    });
  }

  Future<bool> tryMarkAnswered(String notificationId) async {
    final doc = _callsRef.doc(notificationId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      if (!snapshot.exists) return false;

      final call = CallNotification.fromFirestore(snapshot);
      if (!call.isRinging || !call.isFresh(DateTime.now())) {
        return false;
      }

      transaction.update(doc, {
        'status': 'answered',
        'updatedAt': FieldValue.serverTimestamp(),
        'answeredAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<void> markDeclined(String notificationId) {
    return _updateStatus(notificationId, 'declined', 'declinedAt');
  }

  Future<void> markEnded(String notificationId) {
    return _updateStatus(notificationId, 'ended', 'endedAt');
  }

  Future<void> markMissed(String notificationId) {
    return _updateStatus(notificationId, 'missed', 'missedAt');
  }

  Future<void> _updateStatus(
    String notificationId,
    String status,
    String timestampField,
  ) {
    return _callsRef.doc(notificationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      timestampField: FieldValue.serverTimestamp(),
    });
  }
}
