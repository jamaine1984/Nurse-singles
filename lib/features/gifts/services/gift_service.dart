import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/gift_model.dart';

// ─── InventoryItem Model ──────────────────────────────────────────────────

/// Represents a single gift in a user's inventory.
class InventoryItem {
  const InventoryItem({
    required this.giftId,
    required this.giftName,
    required this.giftEmoji,
    required this.quantity,
    required this.claimedAt,
  });

  final String giftId;
  final String giftName;
  final String giftEmoji;
  final int quantity;
  final DateTime claimedAt;

  factory InventoryItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return InventoryItem(
      giftId: data['giftId'] as String? ?? doc.id,
      giftName: data['giftName'] as String? ?? '',
      giftEmoji: data['giftEmoji'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      claimedAt: _toDateTime(data['claimedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'giftId': giftId,
    'giftName': giftName,
    'giftEmoji': giftEmoji,
    'quantity': quantity,
    'claimedAt': Timestamp.fromDate(claimedAt),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'InventoryItem(giftId: $giftId, name: $giftName, qty: $quantity)';
}

// ─── GiftTransaction Model ──────────────────────────────────────────────────

/// Represents a single gift exchange between two users.
class GiftTransaction {
  const GiftTransaction({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.giftId,
    required this.giftName,
    required this.giftEmoji,
    required this.giftPrice,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String giftId;
  final String giftName;
  final String giftEmoji;
  final int giftPrice;
  final DateTime createdAt;

  factory GiftTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return GiftTransaction(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      receiverName: data['receiverName'] as String? ?? '',
      giftId: data['giftId'] as String? ?? '',
      giftName: data['giftName'] as String? ?? '',
      giftEmoji: data['giftEmoji'] as String? ?? '',
      giftPrice: (data['giftPrice'] as num?)?.toInt() ?? 0,
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  factory GiftTransaction.fromMap(Map<String, dynamic> data, String id) {
    return GiftTransaction(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      receiverName: data['receiverName'] as String? ?? '',
      giftId: data['giftId'] as String? ?? '',
      giftName: data['giftName'] as String? ?? '',
      giftEmoji: data['giftEmoji'] as String? ?? '',
      giftPrice: (data['giftPrice'] as num?)?.toInt() ?? 0,
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'senderName': senderName,
    'receiverId': receiverId,
    'receiverName': receiverName,
    'giftId': giftId,
    'giftName': giftName,
    'giftEmoji': giftEmoji,
    'giftPrice': giftPrice,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'GiftTransaction(id: $id, sender: $senderName, receiver: $receiverName, gift: $giftName)';
}

// ─── GiftService ────────────────────────────────────────────────────────────

/// Handles all gift-related Firestore operations including sending gifts,
/// managing gift points, inventory management, and querying transaction history.
class GiftService {
  GiftService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection(AppConstants.giftTransactionsCollection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Returns the inventory subcollection reference for a given user.
  CollectionReference<Map<String, dynamic>> _inventoryRef(String userId) =>
      _usersRef.doc(userId).collection('gift_inventory');

  // ═══════════════════════════════════════════════════════════════════════
  //  INVENTORY METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Claims a gift into the user's inventory after watching an ad.
  ///
  /// If the gift already exists, increments the quantity by 1.
  /// If it does not exist, creates a new inventory entry with quantity 1.
  Future<bool> claimGift({
    required String userId,
    required String giftId,
    required String giftName,
    required String giftEmoji,
  }) async {
    try {
      final docRef = _inventoryRef(userId).doc(giftId);
      final doc = await docRef.get();

      if (doc.exists) {
        // Increment quantity.
        await docRef.update({
          'quantity': FieldValue.increment(1),
          'claimedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new inventory entry.
        await docRef.set({
          'giftId': giftId,
          'giftName': giftName,
          'giftEmoji': giftEmoji,
          'quantity': 1,
          'claimedAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Streams the user's full gift inventory, ordered by most recent claim.
  Stream<List<InventoryItem>> getInventory(String userId) {
    return _inventoryRef(userId)
        .orderBy('claimedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => InventoryItem.fromFirestore(doc))
              .where((item) => item.quantity > 0)
              .toList(),
        );
  }

  /// Checks whether the user owns at least one of this gift.
  Future<bool> hasGift(String userId, String giftId) async {
    try {
      final doc = await _inventoryRef(userId).doc(giftId).get();
      if (!doc.exists) return false;
      final qty = (doc.data()?['quantity'] as num?)?.toInt() ?? 0;
      return qty > 0;
    } catch (_) {
      return false;
    }
  }

  /// Returns a snapshot map of all gift IDs the user owns (id -> quantity).
  ///
  /// Useful for checking "claimed" status in the store page.
  Stream<Map<String, int>> getInventoryMap(String userId) {
    return _inventoryRef(userId).snapshots().map((snap) {
      final map = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final qty = (data['quantity'] as num?)?.toInt() ?? 0;
        if (qty > 0) {
          map[doc.id] = qty;
        }
      }
      return map;
    });
  }

  /// Sends a gift from the user's inventory to another user via chat.
  ///
  /// - Deducts 1 from the sender's inventory.
  /// - Creates a gift_transaction document.
  /// - Creates a gift message in the chat.
  ///
  /// Returns `true` on success.
  Future<bool> sendGiftFromInventory({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required String chatId,
    required String giftId,
    required String giftName,
    required String giftEmoji,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        // 1. Check that the sender has this gift in inventory.
        final invDocRef = _inventoryRef(fromUserId).doc(giftId);
        final invDoc = await transaction.get(invDocRef);

        if (!invDoc.exists) return false;
        final currentQty = (invDoc.data()?['quantity'] as num?)?.toInt() ?? 0;
        if (currentQty <= 0) return false;

        // 2. Deduct from inventory.
        if (currentQty == 1) {
          transaction.delete(invDocRef);
        } else {
          transaction.update(invDocRef, {'quantity': currentQty - 1});
        }

        // 3. Create the gift transaction record.
        final txnRef = _transactionsRef.doc();
        final giftTransaction = GiftTransaction(
          id: txnRef.id,
          senderId: fromUserId,
          senderName: fromUserName,
          receiverId: toUserId,
          receiverName: toUserName,
          giftId: giftId,
          giftName: giftName,
          giftEmoji: giftEmoji,
          giftPrice: 0, // ad-claimed gift, no point cost
          createdAt: DateTime.now(),
        );
        transaction.set(txnRef, giftTransaction.toFirestore());

        // 4. Update sender's stats (only sender can update own doc).
        transaction.update(_usersRef.doc(fromUserId), {
          'stats.giftsSent': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 5. Create a gift message in the chat if chatId is provided.
        if (chatId.isNotEmpty) {
          final msgRef = _firestore
              .collection(AppConstants.chatsCollection)
              .doc(chatId)
              .collection(AppConstants.messagesCollection)
              .doc();

          transaction.set(msgRef, {
            'senderId': fromUserId,
            'text': '$giftEmoji $giftName',
            'type': 'gift',
            'giftId': giftId,
            'giftName': giftName,
            'giftEmoji': giftEmoji,
            'createdAt': FieldValue.serverTimestamp(),
            'readBy': [fromUserId],
          });

          // Update the chat's last message.
          final chatRef = _firestore
              .collection(AppConstants.chatsCollection)
              .doc(chatId);
          transaction.update(chatRef, {
            'lastMessage': 'Sent a gift: $giftEmoji $giftName',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'lastMessageSenderId': fromUserId,
          });
        }

        return true;
      });
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LEGACY POINT-BASED SENDING (kept for backward compatibility)
  // ═══════════════════════════════════════════════════════════════════════

  /// Sends a gift from one user to another using gift points.
  ///
  /// - Checks that the sender has enough giftPoints.
  /// - Deducts the full gift price from the sender.
  /// - Credits half the gift price to the receiver.
  /// - Creates a gift_transaction document.
  /// - Updates both users' stats.
  ///
  /// Returns `true` if the transaction succeeded, `false` otherwise.
  Future<bool> sendGift({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required GiftModel gift,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        // 1. Read the sender's current document.
        final senderDoc = await transaction.get(_usersRef.doc(senderId));
        if (!senderDoc.exists) return false;

        final senderData = senderDoc.data()!;
        final senderPoints = (senderData['giftPoints'] as num?)?.toInt() ?? 0;

        // 2. Check that the sender has enough points.
        if (senderPoints < gift.price) return false;

        // 3. Read the receiver's current document.
        final receiverDoc = await transaction.get(_usersRef.doc(receiverId));
        if (!receiverDoc.exists) return false;

        final receiverData = receiverDoc.data()!;
        final receiverPoints =
            (receiverData['giftPoints'] as num?)?.toInt() ?? 0;

        // 4. Calculate point changes.
        final receiverCredit = (gift.price / 2).floor();

        // 5. Deduct points from sender.
        transaction.update(_usersRef.doc(senderId), {
          'giftPoints': senderPoints - gift.price,
          'stats.giftsSent': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 6. Credit points to receiver.
        transaction.update(_usersRef.doc(receiverId), {
          'giftPoints': receiverPoints + receiverCredit,
          'stats.giftsReceived': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 7. Create the gift transaction document.
        final txnRef = _transactionsRef.doc();
        final giftTransaction = GiftTransaction(
          id: txnRef.id,
          senderId: senderId,
          senderName: senderName,
          receiverId: receiverId,
          receiverName: receiverName,
          giftId: gift.id,
          giftName: gift.name,
          giftEmoji: gift.emoji,
          giftPrice: gift.price,
          createdAt: DateTime.now(),
        );
        transaction.set(txnRef, giftTransaction.toFirestore());

        return true;
      });
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HISTORY QUERIES
  // ═══════════════════════════════════════════════════════════════════════

  /// Streams the complete gift history for a user (both sent and received),
  /// ordered by most recent first.
  Stream<List<GiftTransaction>> getGiftHistory(String userId) {
    final sentStream = _transactionsRef
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => GiftTransaction.fromFirestore(doc))
              .toList(),
        );

    final receivedStream = _transactionsRef
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => GiftTransaction.fromFirestore(doc))
              .toList(),
        );

    return sentStream.asyncExpand((sentList) {
      return receivedStream.map((receivedList) {
        final combined = [...sentList, ...receivedList];
        combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return combined;
      });
    });
  }

  /// Streams gifts received by a specific user, ordered by most recent first.
  Stream<List<GiftTransaction>> getReceivedGifts(String userId) {
    return _transactionsRef
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => GiftTransaction.fromFirestore(doc))
              .toList(),
        );
  }

  /// Streams gifts sent by a specific user, ordered by most recent first.
  Stream<List<GiftTransaction>> getSentGifts(String userId) {
    return _transactionsRef
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => GiftTransaction.fromFirestore(doc))
              .toList(),
        );
  }

  /// Returns the current gift point balance for a user.
  Future<int> getGiftPoints(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return 0;
    return (doc.data()?['giftPoints'] as num?)?.toInt() ?? 0;
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────────────────

final giftServiceProvider = Provider<GiftService>((ref) {
  return GiftService();
});

/// Streams all gift transactions (sent + received) for a given user ID.
final giftHistoryProvider =
    StreamProvider.family<List<GiftTransaction>, String>((ref, userId) {
      final service = ref.watch(giftServiceProvider);
      return service.getGiftHistory(userId);
    });

/// Streams only received gifts for a given user ID.
final receivedGiftsProvider =
    StreamProvider.family<List<GiftTransaction>, String>((ref, userId) {
      final service = ref.watch(giftServiceProvider);
      return service.getReceivedGifts(userId);
    });

/// Streams only sent gifts for a given user ID.
final sentGiftsProvider = StreamProvider.family<List<GiftTransaction>, String>((
  ref,
  userId,
) {
  final service = ref.watch(giftServiceProvider);
  return service.getSentGifts(userId);
});

/// Streams the user's gift inventory as a list of [InventoryItem].
final giftInventoryProvider =
    StreamProvider.family<List<InventoryItem>, String>((ref, userId) {
      final service = ref.watch(giftServiceProvider);
      return service.getInventory(userId);
    });

/// Streams the user's inventory as a map of giftId -> quantity.
/// Used by the gift store page to show claimed status.
final giftInventoryMapProvider =
    StreamProvider.family<Map<String, int>, String>((ref, userId) {
      final service = ref.watch(giftServiceProvider);
      return service.getInventoryMap(userId);
    });
