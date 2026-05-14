import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/models/message_model.dart';
import 'package:nightingale_heart/features/messages/services/message_service.dart';

// Re-export messageServiceProvider so consumers importing this file get it too.
export 'package:nightingale_heart/features/messages/services/message_service.dart'
    show MessageUsageLimitException, messageServiceProvider;

/// Streams all chats for a given user ID, ordered by most recent message.
///
/// Usage:
/// ```dart
/// final chats = ref.watch(chatsProvider(userId));
/// ```
final chatsProvider = StreamProvider.family<List<ChatModel>, String>((
  ref,
  userId,
) {
  final service = ref.watch(messageServiceProvider);
  return service.getChats(userId);
});

/// Streams messages for a given chat ID, ordered newest first.
///
/// Usage:
/// ```dart
/// final messages = ref.watch(messagesProvider(chatId));
/// ```
final messagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  chatId,
) {
  final service = ref.watch(messageServiceProvider);
  return service.getMessages(chatId);
});

/// Streams the total unread message count across all chats for a user.
///
/// Usage:
/// ```dart
/// final unread = ref.watch(totalUnreadProvider(userId));
/// ```
final totalUnreadProvider = StreamProvider.family<int, String>((ref, userId) {
  final service = ref.watch(messageServiceProvider);
  return service.getTotalUnreadCount(userId);
});
