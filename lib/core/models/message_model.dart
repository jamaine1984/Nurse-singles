import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

/// A single chat message stored in `chats/{chatId}/messages/{messageId}`.
class MessageModel {
  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.type = MessageType.text,
    this.giftId,
    this.giftName,
    this.giftEmoji,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final String? giftId;
  final String? giftName;
  final String? giftEmoji;
  final bool isRead;
  final DateTime createdAt;

  // ─── Firestore Factories ─────────────────────────────────────────────

  factory MessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      content: data['content'] as String? ?? '',
      type: MessageType.fromString(data['type'] as String?),
      giftId: data['giftId'] as String?,
      giftName: data['giftName'] as String?,
      giftEmoji: data['giftEmoji'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      content: data['content'] as String? ?? '',
      type: MessageType.fromString(data['type'] as String?),
      giftId: data['giftId'] as String?,
      giftName: data['giftName'] as String?,
      giftEmoji: data['giftEmoji'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'chatId': chatId,
    'senderId': senderId,
    'senderName': senderName,
    'senderPhotoUrl': senderPhotoUrl,
    'content': content,
    'type': type.value,
    'giftId': giftId,
    'giftName': giftName,
    'giftEmoji': giftEmoji,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? content,
    MessageType? type,
    String? giftId,
    String? giftName,
    String? giftEmoji,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      giftId: giftId ?? this.giftId,
      giftName: giftName ?? this.giftName,
      giftEmoji: giftEmoji ?? this.giftEmoji,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'MessageModel(id: $id, senderId: $senderId, type: ${type.value}, content: $content)';
}

/// A chat / conversation document stored at `chats/{chatId}`.
class ChatModel {
  const ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = const {},
    required this.createdAt,
  });

  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final DateTime createdAt;

  // ─── Firestore Factories ─────────────────────────────────────────────

  factory ChatModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChatModel(
      id: doc.id,
      participants: _toStringList(data['participants']),
      participantNames: _toStringMap(data['participantNames']),
      participantPhotos: _toStringMap(data['participantPhotos']),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: _toDateTime(data['lastMessageTime']),
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      unreadCount: _toIntMap(data['unreadCount']),
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  factory ChatModel.fromMap(Map<String, dynamic> data, String id) {
    return ChatModel(
      id: id,
      participants: _toStringList(data['participants']),
      participantNames: _toStringMap(data['participantNames']),
      participantPhotos: _toStringMap(data['participantPhotos']),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: _toDateTime(data['lastMessageTime']),
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      unreadCount: _toIntMap(data['unreadCount']),
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'participants': participants,
    'participantMap': {for (final id in participants) id: true},
    'participantNames': participantNames,
    'participantPhotos': participantPhotos,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime != null
        ? Timestamp.fromDate(lastMessageTime!)
        : null,
    'lastMessageSenderId': lastMessageSenderId,
    'unreadCount': unreadCount,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String>? participantPhotos,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantPhotos: participantPhotos ?? this.participantPhotos,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns the other participant's ID in a 1-to-1 chat.
  String otherUserId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Returns the other participant's display name.
  String otherUserName(String currentUserId) {
    final otherId = otherUserId(currentUserId);
    return participantNames[otherId] ?? 'Unknown';
  }

  /// Returns the other participant's photo URL.
  String? otherUserPhoto(String currentUserId) {
    final otherId = otherUserId(currentUserId);
    return participantPhotos[otherId];
  }

  /// Unread count for the given user.
  int unreadFor(String userId) => unreadCount[userId] ?? 0;

  // ─── Private Helpers ─────────────────────────────────────────────────

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static Map<String, String> _toStringMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return {};
  }

  static Map<String, int> _toIntMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
      );
    }
    return {};
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'ChatModel(id: $id, participants: $participants)';
}
