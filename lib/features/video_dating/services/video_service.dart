import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides the singleton [VideoService].
final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService();
});

// ---------------------------------------------------------------------------
// SpeedDatingRoom model
// ---------------------------------------------------------------------------

/// Data model for a speed-dating room stored in the
/// `speed_dating_rooms` Firestore collection.
class SpeedDatingRoom {
  const SpeedDatingRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.hostId,
    required this.hostName,
    required this.duration,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    this.scheduledTime,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String hostId;
  final String hostName;

  /// Duration in minutes.
  final int duration;
  final int maxParticipants;
  final List<String> currentParticipants;

  /// One of: `waiting`, `active`, `ended`.
  final String status;
  final DateTime? scheduledTime;
  final DateTime? createdAt;

  // ---- Firestore serialisation -------------------------------------------

  factory SpeedDatingRoom.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return SpeedDatingRoom(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      hostId: data['hostId'] as String? ?? '',
      hostName: data['hostName'] as String? ?? '',
      duration: (data['duration'] as num?)?.toInt() ?? 5,
      maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 2,
      currentParticipants: _toStringList(data['currentParticipants']),
      status: data['status'] as String? ?? 'waiting',
      scheduledTime: _toDateTime(data['scheduledTime']),
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'hostId': hostId,
    'hostName': hostName,
    'duration': duration,
    'maxParticipants': maxParticipants,
    'currentParticipants': currentParticipants,
    'status': status,
    'scheduledTime': scheduledTime != null
        ? Timestamp.fromDate(scheduledTime!)
        : FieldValue.serverTimestamp(),
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };

  // ---- Convenience getters -----------------------------------------------

  bool get isFull => currentParticipants.length >= maxParticipants;
  bool get isWaiting => status == 'waiting';
  bool get isActive => status == 'active';
  int get participantCount => currentParticipants.length;

  // ---- Helpers -----------------------------------------------------------

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
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
// SpeedDatingSession model
// ---------------------------------------------------------------------------

/// A 1-on-1 video session within a speed-dating room.
class SpeedDatingSession {
  const SpeedDatingSession({
    required this.id,
    required this.roomId,
    required this.participants,
    required this.status,
    this.startTime,
    this.endTime,
    this.duration,
  });

  final String id;
  final String roomId;
  final List<String> participants;

  /// `active` or `completed`.
  final String status;
  final DateTime? startTime;
  final DateTime? endTime;

  /// Actual call duration in seconds.
  final int? duration;

  factory SpeedDatingSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return SpeedDatingSession(
      id: doc.id,
      roomId: data['roomId'] as String? ?? '',
      participants: SpeedDatingRoom._toStringList(data['participants']),
      status: data['status'] as String? ?? 'active',
      startTime: SpeedDatingRoom._toDateTime(data['startTime']),
      endTime: SpeedDatingRoom._toDateTime(data['endTime']),
      duration: (data['duration'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'roomId': roomId,
    'participants': participants,
    'status': status,
    'startTime': startTime != null
        ? Timestamp.fromDate(startTime!)
        : FieldValue.serverTimestamp(),
    'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    'duration': duration,
  };
}

// ---------------------------------------------------------------------------
// VideoService
// ---------------------------------------------------------------------------

class VideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection(AppConstants.speedDatingRoomsCollection);

  CollectionReference<Map<String, dynamic>> get _sessionsRef =>
      _firestore.collection(AppConstants.speedDatingSessionsCollection);

  CollectionReference<Map<String, dynamic>> get _videoSessionsRef =>
      _firestore.collection(AppConstants.videoSessionsCollection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  // ---- Rooms -------------------------------------------------------------

  /// Streams all rooms whose status is not `ended`, ordered by scheduledTime.
  Stream<List<SpeedDatingRoom>> getRooms() {
    return _roomsRef
        .where('status', isNotEqualTo: 'ended')
        .orderBy('status')
        .orderBy('scheduledTime', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SpeedDatingRoom.fromFirestore(doc))
              .toList();
        });
  }

  /// Streams rooms where the given [userId] is a participant.
  Stream<List<SpeedDatingRoom>> getMyRooms(String userId) {
    return _roomsRef
        .where('currentParticipants', arrayContains: userId)
        .orderBy('scheduledTime', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SpeedDatingRoom.fromFirestore(doc))
              .toList();
        });
  }

  /// Creates a new room and returns its document id.
  Future<String> createRoom({
    required String name,
    required String description,
    required String hostId,
    required String hostName,
    required int duration,
    required int maxParticipants,
  }) async {
    final doc = await _roomsRef.add({
      'name': name,
      'description': description,
      'hostId': hostId,
      'hostName': hostName,
      'duration': duration,
      'maxParticipants': maxParticipants,
      'currentParticipants': [hostId],
      'status': 'waiting',
      'scheduledTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[VideoService] Room created: ${doc.id}');
    return doc.id;
  }

  /// Adds [userId] to the room's `currentParticipants` list.
  Future<void> joinRoom(String roomId, String userId) async {
    final callable = _functions.httpsCallable('joinSpeedDatingRoom');
    await callable.call<Map<String, dynamic>>({'roomId': roomId});
    debugPrint('[VideoService] User $userId joined room $roomId');
  }

  /// Removes [userId] from the room's `currentParticipants` list.
  Future<void> leaveRoom(String roomId, String userId) async {
    final callable = _functions.httpsCallable('leaveSpeedDatingRoom');
    await callable.call<Map<String, dynamic>>({'roomId': roomId});
    debugPrint('[VideoService] User $userId left room $roomId');
  }

  /// Updates a room's status (e.g. `waiting` -> `active` -> `ended`).
  Future<void> updateRoomStatus(String roomId, String status) async {
    if (status == 'active') {
      await activateSpeedDatingRoom(roomId);
      return;
    }
    if (status == 'waiting' || status == 'ended') {
      final callable = _functions.httpsCallable('leaveSpeedDatingRoom');
      await callable.call<Map<String, dynamic>>({'roomId': roomId});
      return;
    }
    throw ArgumentError.value(status, 'status', 'Unsupported room status');
  }

  Future<void> activateSpeedDatingRoom(String roomId) async {
    final callable = _functions.httpsCallable('activateSpeedDatingRoom');
    await callable.call<Map<String, dynamic>>({'roomId': roomId});
  }

  Future<SpeedDateFollowUpResult> submitSpeedDateFollowUp({
    required String sessionId,
    required String roomId,
    required String otherUserId,
    required bool wantsToConnect,
  }) async {
    final callable = _functions.httpsCallable('submitSpeedDateFollowUp');
    final response = await callable.call<Map<String, dynamic>>({
      'sessionId': sessionId,
      'roomId': roomId,
      'otherUserId': otherUserId,
      'wantsToConnect': wantsToConnect,
    });
    return SpeedDateFollowUpResult.fromMap(response.data);
  }

  Stream<SpeedDateFollowUpResult> watchSpeedDateFollowUp(String sessionId) {
    return _firestore
        .collection(AppConstants.speedDateFollowUpsCollection)
        .doc(sessionId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) {
            return const SpeedDateFollowUpResult(status: 'pending');
          }
          return SpeedDateFollowUpResult.fromMap(data);
        });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSpeedDatingRoom(
    String roomId,
  ) {
    return _roomsRef.doc(roomId).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getSpeedDatingRoom(
    String roomId,
  ) {
    return _roomsRef.doc(roomId).get();
  }

  Future<void> endSpeedDatingRoom({
    required String roomId,
    required String endedByUserId,
  }) async {
    final callable = _functions.httpsCallable('leaveSpeedDatingRoom');
    await callable.call<Map<String, dynamic>>({'roomId': roomId});
    debugPrint('[VideoService] Speed dating room $roomId ended');
  }

  static List<String> participantIdsFromRoomData(Map<String, dynamic> data) {
    final ids = <String>{};
    for (final key in ['user1Id', 'user2Id']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) ids.add(value);
    }
    final currentParticipants = data['currentParticipants'];
    if (currentParticipants is List) {
      for (final value in currentParticipants) {
        final id = value?.toString() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
    }
    return ids.toList(growable: false);
  }

  static Map<String, Object?> clearedRoomFields(String endedByUserId) {
    return {
      'status': 'waiting',
      'startedAt': null,
      'activeSessionId': null,
      'lastEndedAt': FieldValue.serverTimestamp(),
      'lastEndedBy': endedByUserId,
      'currentParticipants': <String>[],
      'user1Id': null,
      'user1Name': null,
      'user1PhotoUrl': null,
      'user1Age': null,
      'user2Id': null,
      'user2Name': null,
      'user2PhotoUrl': null,
      'user2Age': null,
    };
  }

  // ---- Sessions ----------------------------------------------------------

  /// Starts a 1-on-1 session between two participants and returns the
  /// session document id.
  Future<String> startSession(
    String roomId,
    String participant1,
    String participant2,
  ) async {
    final doc = await _sessionsRef.add({
      'roomId': roomId,
      'participants': [participant1, participant2],
      'status': 'active',
      'startTime': FieldValue.serverTimestamp(),
      'endTime': null,
      'duration': null,
    });

    // Also log in the general video_sessions collection.
    await _videoSessionsRef.add({
      'callerId': participant1,
      'receiverId': participant2,
      'duration': 0,
      'type': 'speedDate',
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[VideoService] Session started: ${doc.id}');
    return doc.id;
  }

  /// Marks a session as completed, recording the actual [duration] in seconds.
  Future<void> endSession(String sessionId, int duration) async {
    await _sessionsRef.doc(sessionId).update({
      'status': 'completed',
      'endTime': FieldValue.serverTimestamp(),
      'duration': duration,
    });
    debugPrint('[VideoService] Session $sessionId ended ($duration s)');
  }

  // ---- Video Minutes -----------------------------------------------------

  /// Streams the `videoMinutes` field from the user's document.
  Stream<int> getUserVideoMinutes(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return AppConstants.defaultVideoMinutes;
      return (data['videoMinutes'] as num?)?.toInt() ??
          AppConstants.defaultVideoMinutes;
    });
  }

  Future<int> getUserVideoMinutesOnce(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    final data = doc.data();
    if (data == null) return AppConstants.defaultVideoMinutes;
    return (data['videoMinutes'] as num?)?.toInt() ??
        AppConstants.defaultVideoMinutes;
  }

  /// Grants rewarded-ad video minutes through a server-side callable.
  Future<int> addVideoMinutes(String userId, int minutes) async {
    final granted = await _claimVideoMinuteReward(
      userId: userId,
      rewardType: 'ad',
    );
    debugPrint('[VideoService] Added $granted min to user $userId');
    return granted;
  }

  /// Video minutes are deducted by `completeZegoCallSession` on the backend.
  Future<void> deductVideoMinutes(String userId, int minutes) async {
    throw UnsupportedError(
      'Video minutes are deducted by completeZegoCallSession.',
    );
  }

  /// Checks whether the user has already claimed the daily login bonus today.
  Future<bool> hasClaimedDailyBonus(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    final data = doc.data();
    if (data == null) return false;
    final lastClaimed = data['lastDailyBonusClaimed'];
    if (lastClaimed == null) return false;

    final DateTime claimedDate;
    if (lastClaimed is Timestamp) {
      claimedDate = lastClaimed.toDate();
    } else {
      return false;
    }

    final now = DateTime.now();
    return claimedDate.year == now.year &&
        claimedDate.month == now.month &&
        claimedDate.day == now.day;
  }

  /// Claims the daily login bonus through a server-side callable.
  Future<int> claimDailyBonus(String userId, int minutes) {
    return _claimVideoMinuteReward(userId: userId, rewardType: 'daily');
  }

  /// Returns profile completion percentage (0-100).
  Future<int> getProfileCompletion(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    final data = doc.data();
    if (data == null) return 0;

    int filled = 0;
    const fields = [
      'name',
      'photoUrl',
      'jobTitle',
      'hospital',
      'department',
      'location',
      'bio',
      'age',
      'gender',
      'lookingFor',
      'shiftType',
    ];

    for (final field in fields) {
      final value = data[field];
      if (value != null && value.toString().isNotEmpty) {
        filled++;
      }
    }

    final interests = data['interests'];
    if (interests is List && interests.isNotEmpty) filled++;

    final gallery = data['gallery'];
    if (gallery is List && gallery.isNotEmpty) filled++;

    const total = 13; // fields.length + interests + gallery
    return ((filled / total) * 100).round();
  }

  /// Checks if user has received the profile completion bonus.
  Future<bool> hasClaimedProfileBonus(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    return doc.data()?['profileBonusClaimed'] == true;
  }

  /// Claims the profile completion bonus through a server-side callable.
  Future<int> claimProfileBonus(String userId, int minutes) {
    return _claimVideoMinuteReward(
      userId: userId,
      rewardType: 'profile_complete',
    );
  }

  /// Records one rewarded-ad credit toward a profile boost.
  Future<int> recordBoostAdCredit(String userId) async {
    final callable = _functions.httpsCallable('recordBoostAdCredit');
    final response = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });
    return (response.data['boostAdCredits'] as num?)?.toInt() ?? 0;
  }

  /// Activates a profile boost using either plan entitlement or ad credits.
  Future<BoostActivationResult> activateProfileBoost(String userId) async {
    final callable = _functions.httpsCallable('activateProfileBoost');
    final response = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });
    return BoostActivationResult.fromMap(response.data);
  }

  Future<int> _claimVideoMinuteReward({
    required String userId,
    required String rewardType,
  }) async {
    final callable = _functions.httpsCallable('claimVideoMinuteReward');
    final response = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'rewardType': rewardType,
    });
    return (response.data['minutesGranted'] as num?)?.toInt() ?? 0;
  }
}

class BoostActivationResult {
  const BoostActivationResult({
    required this.expiresAt,
    required this.boostAdCredits,
    required this.boostSource,
  });

  final DateTime expiresAt;
  final int boostAdCredits;
  final String boostSource;

  factory BoostActivationResult.fromMap(Map<String, dynamic> data) {
    final expiresAtMs = (data['expiresAt'] as num?)?.toInt();
    return BoostActivationResult(
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMs ?? 0),
      boostAdCredits: (data['boostAdCredits'] as num?)?.toInt() ?? 0,
      boostSource: data['boostSource'] as String? ?? 'rewarded_ads',
    );
  }
}

class SpeedDateFollowUpResult {
  const SpeedDateFollowUpResult({required this.status, this.chatId});

  final String status;
  final String? chatId;

  factory SpeedDateFollowUpResult.fromMap(Map<String, dynamic> data) {
    return SpeedDateFollowUpResult(
      status: data['status'] as String? ?? 'pending',
      chatId: data['chatId'] as String?,
    );
  }
}
