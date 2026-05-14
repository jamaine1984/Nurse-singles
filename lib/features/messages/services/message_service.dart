import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/message_model.dart';
import 'package:nightingale_heart/core/models/user_model.dart';

/// Riverpod provider for [MessageService].
final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService();
});

class MessageUsageLimitException implements Exception {
  MessageUsageLimitException({
    required this.usageType,
    this.plan,
    this.limit,
    this.used,
  });

  final String usageType;
  final String? plan;
  final int? limit;
  final int? used;

  factory MessageUsageLimitException.fromFunctionsException(
    FirebaseFunctionsException error,
  ) {
    final details = error.details;
    if (details is Map) {
      return MessageUsageLimitException(
        usageType: details['usageType']?.toString() ?? 'messages',
        plan: details['plan']?.toString(),
        limit: (details['limit'] as num?)?.toInt(),
        used: (details['used'] as num?)?.toInt(),
      );
    }
    return MessageUsageLimitException(usageType: 'messages');
  }

  @override
  String toString() => 'MessageUsageLimitException($usageType)';
}

/// Service handling Firestore reads and backend-authoritative message sends.
class MessageService {
  MessageService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _firestore.collection(AppConstants.chatsCollection);

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) =>
      _chatsRef.doc(chatId).collection(AppConstants.messagesCollection);

  Stream<List<ChatModel>> getChats(String userId) {
    return _chatsRef
        .where(_participantMapField(userId), isEqualTo: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
          chats.sort(
            (a, b) => _compareDateDesc(a.lastMessageTime, b.lastMessageTime),
          );
          return chats;
        });
  }

  Future<String> createChat(UserModel currentUser, UserModel otherUser) async {
    _throwIfBlocked(currentUser, otherUser);

    final existing = await _findExistingChat(currentUser.id, otherUser.id);
    if (existing != null) return existing;

    final now = DateTime.now();
    final chatDoc = _chatsRef.doc();
    final chat = ChatModel(
      id: chatDoc.id,
      participants: [currentUser.id, otherUser.id],
      participantNames: {
        currentUser.id: currentUser.name,
        otherUser.id: otherUser.name,
      },
      participantPhotos: {
        if (currentUser.photoUrl != null) currentUser.id: currentUser.photoUrl!,
        if (otherUser.photoUrl != null) otherUser.id: otherUser.photoUrl!,
      },
      lastMessage: null,
      lastMessageTime: now,
      lastMessageSenderId: null,
      unreadCount: {currentUser.id: 0, otherUser.id: 0},
      createdAt: now,
    );

    await chatDoc.set(chat.toFirestore());
    return chatDoc.id;
  }

  Future<String?> _findExistingChat(
    String currentUserId,
    String otherUserId,
  ) async {
    final query = await _chatsRef
        .where(_participantMapField(currentUserId), isEqualTo: true)
        .limit(100)
        .get();

    for (final doc in query.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return doc.id;
      }
    }
    return null;
  }

  Future<String> getOrCreateChat(
    String currentUserId,
    String otherUserId,
  ) async {
    final existing = await _findExistingChat(currentUserId, otherUserId);
    if (existing != null) return existing;

    final usersRef = _firestore.collection(AppConstants.usersCollection);
    final currentDoc = await usersRef.doc(currentUserId).get();
    final otherDoc = await usersRef.doc(otherUserId).get();

    if (!currentDoc.exists || !otherDoc.exists) {
      throw Exception('One or both user profiles not found.');
    }

    final currentUser = UserModel.fromFirestore(currentDoc);
    final otherUser = UserModel.fromFirestore(otherDoc);
    _throwIfBlocked(currentUser, otherUser);

    return createChat(currentUser, otherUser);
  }

  Future<void> deleteChat(String chatId) async {
    final messages = await _messagesRef(chatId).get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_chatsRef.doc(chatId));
    await batch.commit();
  }

  Stream<List<MessageModel>> getMessages(
    String chatId, {
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _messagesRef(
      chatId,
    ).orderBy('createdAt', descending: true).limit(AppConstants.chatPageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<MessageModel>> getMessagePage(
    String chatId, {
    DocumentSnapshot? startAfter,
    int limit = 30,
  }) async {
    Query<Map<String, dynamic>> query = _messagesRef(
      chatId,
    ).orderBy('createdAt', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
  }

  Future<DocumentSnapshot?> getMessageSnapshot(
    String chatId,
    String messageId,
  ) async {
    final doc = await _messagesRef(chatId).doc(messageId).get();
    return doc.exists ? doc : null;
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    try {
      final callable = _functions.httpsCallable('sendChatMessage');
      await callable.call<Map<String, dynamic>>({
        'chatId': chatId,
        'content': message.content,
        'type': message.type.value,
        if (message.giftId != null) 'giftId': message.giftId,
        if (message.giftName != null) 'giftName': message.giftName,
        if (message.giftEmoji != null) 'giftEmoji': message.giftEmoji,
      });
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'resource-exhausted') {
        throw MessageUsageLimitException.fromFunctionsException(error);
      }
      rethrow;
    }
  }

  void _throwIfBlocked(UserModel currentUser, UserModel otherUser) {
    if (currentUser.blocked.contains(otherUser.id) ||
        otherUser.blocked.contains(currentUser.id)) {
      throw StateError('Messaging is unavailable for this profile.');
    }
  }

  Future<void> sendGiftMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String giftId,
    required String giftName,
    String? giftEmoji,
  }) async {
    final message = MessageModel(
      id: '',
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      content: '${giftEmoji ?? 'Gift'} Sent a $giftName!',
      type: MessageType.gift,
      giftId: giftId,
      giftName: giftName,
      giftEmoji: giftEmoji,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await sendMessage(chatId, message);
  }

  Future<void> markAsRead(String chatId, String userId) async {
    final unreadQuery = await _messagesRef(
      chatId,
    ).where('isRead', isEqualTo: false).get();
    final unreadMessagesFromOthers = unreadQuery.docs
        .where((doc) => doc.data()['senderId'] != userId)
        .toList(growable: false);

    if (unreadMessagesFromOthers.isEmpty) {
      await _chatsRef.doc(chatId).update({'unreadCount.$userId': 0});
      return;
    }

    final batch = _firestore.batch();
    for (final doc in unreadMessagesFromOthers) {
      batch.update(doc.reference, {'isRead': true});
    }
    batch.update(_chatsRef.doc(chatId), {'unreadCount.$userId': 0});
    await batch.commit();
  }

  Stream<int> getTotalUnreadCount(String userId) {
    return _chatsRef
        .where(_participantMapField(userId), isEqualTo: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          var total = 0;
          for (final doc in snapshot.docs) {
            final unread = doc.data()['unreadCount'] as Map<String, dynamic>?;
            if (unread != null && unread.containsKey(userId)) {
              total += (unread[userId] as num?)?.toInt() ?? 0;
            }
          }
          return total;
        });
  }

  static int _compareDateDesc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  static String _participantMapField(String userId) => 'participantMap.$userId';
}
