import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/message_model.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/call_notification_service.dart';
import 'package:nightingale_heart/core/services/safety_service.dart';
import 'package:nightingale_heart/core/services/storage_service.dart';
import 'package:nightingale_heart/core/services/usage_limits_service.dart';
import 'package:nightingale_heart/core/widgets/limit_reached_dialog.dart';
import 'package:nightingale_heart/features/messages/providers/message_providers.dart';
import 'package:nightingale_heart/features/messages/widgets/message_bubble.dart';
import 'package:nightingale_heart/features/messages/widgets/chat_input.dart';
import 'package:nightingale_heart/features/gifts/pages/gift_select_page.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

// ─── Color Constants ─────────────────────────────────────────────────────────
const Color _deepPlum = Color(0xFF0F766E);
const Color _warmRose = Color(0xFFDC2626);
const Color _softAmber = Color(0xFFF59E0B);
const Color _cream = Color(0xFFFFFBEB);
const Color _softLavender = Color(0xFFF3E8FF);
const Duration _maxVoiceNoteDuration = Duration(
  seconds: AppConstants.maxVoiceMessageSeconds,
);

/// Individual chat page for a 1-on-1 conversation.
///
/// Displays the message history in a reverse ListView with date separators,
/// supports text, image, gift, video call, and system messages, and provides
/// a rich input bar with emoji picker, attachments, and a send button.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  final List<MessageModel> _olderMessages = [];

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);

    // Mark messages as read after frame renders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
      _recordChatOpenCost();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markAsRead();
    }
  }

  void _markAsRead() {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser != null) {
      final service = ref.read(messageServiceProvider);
      unawaited(
        service.markAsRead(widget.chatId, currentUser.id).catchError((error) {
          debugPrint('[ChatPage] Mark as read failed: $error');
        }),
      );
    }
  }

  void _recordChatOpenCost() {
    unawaited(_recordChatOpenCostAsync());
  }

  Future<void> _recordChatOpenCostAsync() async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('recordCostTelemetry')
          .call<Map<String, dynamic>>({
            'feature': 'chat_open',
            'amount': AppConstants.chatPageSize,
            'unit': 'estimated_message_reads',
            'metadata': {'chatId': widget.chatId},
          });
    } catch (_) {
      // Cost telemetry should not block chat.
    }
  }

  /// Loads older messages when scrolling to the top (bottom of reversed list).
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final service = ref.read(messageServiceProvider);

      // Get the cursor for the oldest loaded message.
      DocumentSnapshot? cursor;
      if (_olderMessages.isNotEmpty) {
        cursor = await service.getMessageSnapshot(
          widget.chatId,
          _olderMessages.last.id,
        );
      }

      final older = await service.getMessagePage(
        widget.chatId,
        startAfter: cursor,
        limit: AppConstants.chatPageSize,
      );

      if (mounted) {
        setState(() {
          _olderMessages.addAll(older);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return Scaffold(
            body: Center(child: Text(_t('please_sign_in_messages'))),
          );
        }
        return _buildChatScaffold(context, currentUser);
      },
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0B15) : _cream,
        body: const Center(child: CircularProgressIndicator(color: _deepPlum)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildChatScaffold(BuildContext context, UserModel currentUser) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final chatsAsync = ref.watch(chatsProvider(currentUser.id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve the chat model to get the other user's info.
    ChatModel? chat;
    chatsAsync.whenData((chats) {
      for (final c in chats) {
        if (c.id == widget.chatId) {
          chat = c;
          break;
        }
      }
    });

    final otherName = chat?.otherUserName(currentUser.id) ?? 'Chat';
    final otherPhoto = chat?.otherUserPhoto(currentUser.id);
    final otherUserId = chat?.otherUserId(currentUser.id) ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0B15) : _cream,
      appBar: _buildAppBar(context, otherName, otherPhoto, otherUserId),
      body: Column(
        children: [
          // ── Message List ──────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              data: (streamMessages) {
                // Mark as read whenever new messages arrive.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markAsRead();
                });

                // Combine streamed messages with paginated older messages.
                // The stream already returns newest first.
                final allMessages = [
                  ...streamMessages,
                  ..._olderMessages.where(
                    (old) => !streamMessages.any((m) => m.id == old.id),
                  ),
                ];

                if (allMessages.isEmpty) {
                  return _buildEmptyChat(context);
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: allMessages.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoadingMore && index == allMessages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _deepPlum,
                            ),
                          ),
                        ),
                      );
                    }

                    final message = allMessages[index];
                    final isMe = message.senderId == currentUser.id;

                    // Date separator: show if this message's date differs
                    // from the next (older) one.
                    Widget? dateSeparator;
                    if (index < allMessages.length - 1) {
                      final nextMessage = allMessages[index + 1];
                      if (!_isSameDay(
                        message.createdAt,
                        nextMessage.createdAt,
                      )) {
                        dateSeparator = _buildDateSeparator(
                          context,
                          nextMessage.createdAt,
                        );
                      }
                    } else {
                      // Last item -- show its date separator above it.
                      dateSeparator = _buildDateSeparator(
                        context,
                        message.createdAt,
                      );
                    }

                    return Column(
                      children: [
                        if (dateSeparator != null) dateSeparator,
                        MessageBubble(
                          message: message,
                          isMe: isMe,
                          videoCallLabel: _t('video_call'),
                          tapToJoinLabel: _t('tap_to_join'),
                          onVideoCallTap: message.type == MessageType.videoCall
                              ? () {
                                  final invite = _videoCallInviteFromContent(
                                    message.content,
                                  );
                                  unawaited(
                                    _handleVideoCall(
                                      context,
                                      otherUserId,
                                      otherName,
                                      sendInvite: false,
                                      roomIdOverride: invite.roomId,
                                      callNotificationId:
                                          invite.callNotificationId,
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: _deepPlum),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),

          // ── Input Bar ────────────────────────────────────────────────
          ChatInput(
            onSendMessage: (text) => _handleSendText(currentUser, text),
            onSendImage: () => _handleSendImage(currentUser),
            onSendGift: () => _handleSendGift(context, otherUserId, otherName),
            onStartVideoCall: () =>
                _handleVideoCall(context, otherUserId, otherName),
            onSendVoiceNote: () => _handleVoiceNote(context, currentUser),
            photoLabel: _t('photo'),
            giftLabel: _t('gift'),
            videoCallLabel: _t('video_call'),
            messageHint: _t('type_message'),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String otherName,
    String? otherPhoto,
    String otherUserId,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1A1523) : Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: () {
          if (otherUserId.isNotEmpty) {
            context.push('/profile/$otherUserId');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _softLavender,
                backgroundImage: otherPhoto != null
                    ? CachedNetworkImageProvider(otherPhoto)
                    : null,
                child: otherPhoto == null
                    ? Text(
                        otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _deepPlum,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Online',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF06B6D4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded, color: _deepPlum),
          onPressed: () => _handleVideoCall(context, otherUserId, otherName),
          tooltip: 'Video Call',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _showChatOptions(context, otherUserId, otherName),
          tooltip: 'More options',
        ),
      ],
    );
  }

  // ─── Empty Chat ─────────────────────────────────────────────────────────
  Widget _buildEmptyChat(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.waving_hand_rounded,
              size: 64,
              color: _softAmber.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 20),
            Text(
              'Say hello!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to start the conversation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  // ─── Date Separator ─────────────────────────────────────────────────────
  Widget _buildDateSeparator(BuildContext context, DateTime dateTime) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    String label;

    if (_isSameDay(dateTime, now)) {
      label = 'Today';
    } else if (_isSameDay(dateTime, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ─── Send Handlers ──────────────────────────────────────────────────────

  Future<bool> _sendMessageWithLimitHandling(
    UserModel currentUser,
    MessageModel message,
    String fallbackError,
  ) async {
    try {
      await ref
          .read(messageServiceProvider)
          .sendMessage(widget.chatId, message);
      return true;
    } on MessageUsageLimitException {
      if (!mounted) return false;
      final planFeatures =
          AppConstants.planFeatures[currentUser.plan] ??
          AppConstants.planFeatures[SubscriptionPlan.free]!;
      final refillAmount = planFeatures['adRefillMessages'] as int? ?? 0;
      if (refillAmount > 0) {
        final refilled = await showLimitReachedDialog(
          context: context,
          userId: currentUser.id,
          limitType: 'messages',
          refillAmount: refillAmount,
        );
        if (!refilled) return false;
        try {
          await ref
              .read(messageServiceProvider)
              .sendMessage(widget.chatId, message);
          return true;
        } on MessageUsageLimitException {
          _showMessageError(_t('daily_messages_used'));
          return false;
        }
      }
      _showMessageError(_t('daily_messages_used'));
      return false;
    } catch (error) {
      debugPrint('[ChatPage] Send message failed: $error');
      _showMessageError(fallbackError);
      return false;
    }
  }

  void _showMessageError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _warmRose,
      ),
    );
  }

  Future<void> _handleSendText(UserModel currentUser, String text) async {
    if (text.trim().isEmpty) return;

    try {
      // ── Check daily message limit ──
      final usageLimitsService = ref.read(usageLimitsServiceProvider);
      bool canSend = true;
      try {
        canSend = await usageLimitsService.canSendMessage(
          currentUser.id,
          currentUser.plan,
        );
      } catch (e) {
        // If usage check fails, allow sending (don't block on tracking errors)
        debugPrint('[ChatPage] Usage limit check failed: $e');
      }

      if (!canSend && mounted) {
        final planFeatures = AppConstants.planFeatures[currentUser.plan]!;
        final refillAmount = planFeatures['adRefillMessages'] as int;

        if (refillAmount > 0) {
          final refilled = await showLimitReachedDialog(
            context: context,
            userId: currentUser.id,
            limitType: 'messages',
            refillAmount: refillAmount,
          );
          if (!refilled) return;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You\'ve used all your daily messages.',
                  style: GoogleFonts.plusJakartaSans(),
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: _warmRose,
              ),
            );
          }
          return;
        }
      }

      final message = MessageModel(
        id: '',
        chatId: widget.chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderPhotoUrl: currentUser.photoUrl,
        content: text.trim(),
        type: MessageType.text,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _sendMessageWithLimitHandling(
        currentUser,
        message,
        'Failed to send message. Please try again.',
      );
    } catch (e) {
      debugPrint('[ChatPage] Send message error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send message. Please try again.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _warmRose,
          ),
        );
      }
    }
  }

  Future<void> _handleSendImage(UserModel currentUser) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );

    if (picked == null) return;

    try {
      final storageService = ref.read(storageServiceProvider);
      final downloadUrl = await storageService.uploadChatImage(
        userId: currentUser.id,
        chatId: widget.chatId,
        file: File(picked.path),
      );

      final message = MessageModel(
        id: '',
        chatId: widget.chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderPhotoUrl: currentUser.photoUrl,
        content: downloadUrl,
        type: MessageType.image,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _sendMessageWithLimitHandling(
        currentUser,
        message,
        'Failed to send image. Please try again.',
      );
    } catch (e) {
      debugPrint('[ChatPage] Image send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send image. Please try again.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _warmRose,
          ),
        );
      }
    }
  }

  void _handleSendGift(
    BuildContext context,
    String receiverId,
    String receiverName,
  ) {
    if (receiverId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GiftSelectPage(
          receiverId: receiverId,
          receiverName: receiverName,
          chatId: widget.chatId,
        ),
      ),
    );
  }

  void _handleVoiceNote(BuildContext context, UserModel currentUser) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _VoiceRecordSheet(
        onSend: (String filePath, Duration duration) async {
          Navigator.of(ctx).pop();
          await _uploadAndSendVoice(currentUser, filePath, duration);
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _uploadAndSendVoice(
    UserModel currentUser,
    String filePath,
    Duration duration,
  ) async {
    try {
      if (duration > _maxVoiceNoteDuration) {
        try {
          await File(filePath).delete();
        } catch (_) {}
        _showMessageError('Voice messages can be 15 seconds max.');
        return;
      }

      final file = File(filePath);
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storageRef = FirebaseStorage.instance.ref().child(
        'chats/${widget.chatId}/voice/$fileName',
      );

      await storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'audio/mp4',
          customMetadata: {'uploadedBy': currentUser.id},
        ),
      );
      final downloadUrl = await storageRef.getDownloadURL();

      final mins = duration.inMinutes;
      final secs = duration.inSeconds % 60;
      final durationStr =
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

      final message = MessageModel(
        id: '',
        chatId: widget.chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderPhotoUrl: currentUser.photoUrl,
        content: '$durationStr|$downloadUrl',
        type: MessageType.voiceNote,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final sent = await _sendMessageWithLimitHandling(
        currentUser,
        message,
        'Failed to send voice note.',
      );
      if (!sent) return;

      // Clean up temp file
      try {
        await file.delete();
      } catch (_) {}
    } catch (e) {
      debugPrint('[ChatPage] Voice note error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send voice note.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _warmRose,
          ),
        );
      }
    }
  }

  Future<void> _handleVideoCall(
    BuildContext context,
    String otherUserId,
    String otherName, {
    bool sendInvite = true,
    String? roomIdOverride,
    String? callNotificationId,
  }) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null || otherUserId.isEmpty) return;

    final roomId =
        roomIdOverride ??
        (sendInvite
            ? 'chat_${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}'
            : 'chat_${widget.chatId}');
    String? createdCallNotificationId;
    var inviteMessageSent = false;

    if (sendInvite) {
      createdCallNotificationId = ref
          .read(callNotificationServiceProvider)
          .createNotificationId();
      try {
        final message = MessageModel(
          id: '',
          chatId: widget.chatId,
          senderId: currentUser.id,
          senderName: currentUser.name,
          senderPhotoUrl: currentUser.photoUrl,
          content: 'room:$roomId;call:$createdCallNotificationId',
          type: MessageType.videoCall,
          isRead: false,
          createdAt: DateTime.now(),
        );
        await ref
            .read(messageServiceProvider)
            .sendMessage(widget.chatId, message);
        inviteMessageSent = true;
      } catch (error) {
        debugPrint('[ChatPage] Failed to send video call invite: $error');
      }

      if (inviteMessageSent) {
        try {
          await ref
              .read(callNotificationServiceProvider)
              .createOneOnOneCallNotification(
                notificationId: createdCallNotificationId,
                callerId: currentUser.id,
                callerName: currentUser.name,
                receiverId: otherUserId,
                roomId: roomId,
                chatId: widget.chatId,
              );
        } catch (error) {
          debugPrint(
            '[ChatPage] Failed to create video call notification: $error',
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_t('video_calling_unavailable'))),
          );
        }
        return;
      }
    } else if (callNotificationId != null && callNotificationId.isNotEmpty) {
      try {
        final answered = await ref
            .read(callNotificationServiceProvider)
            .tryMarkAnswered(callNotificationId);
        if (!answered) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_t('call_no_longer_available'))),
            );
          }
          return;
        }
      } catch (error) {
        debugPrint('[ChatPage] Failed to answer call notification: $error');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_t('call_no_longer_available'))),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    final uri = Uri(
      path: '/video/call/$roomId',
      queryParameters: {
        'type': 'oneOnOne',
        'targetUserId': otherUserId,
        'targetUserName': otherName,
        'chatId': widget.chatId,
        if ((createdCallNotificationId ?? callNotificationId)?.isNotEmpty ==
            true)
          'callNotificationId': createdCallNotificationId ?? callNotificationId,
      },
    );
    context.push(uri.toString());
  }

  _VideoCallInvite _videoCallInviteFromContent(String content) {
    String? roomId;
    String? callNotificationId;

    for (final part in content.split(';')) {
      final separator = part.indexOf(':');
      if (separator <= 0) continue;
      final key = part.substring(0, separator).trim();
      final value = part.substring(separator + 1).trim();
      if (value.isEmpty) continue;
      if (key == 'room') {
        roomId = value;
      } else if (key == 'call') {
        callNotificationId = value;
      }
    }

    return _VideoCallInvite(
      roomId: roomId,
      callNotificationId: callNotificationId,
    );
  }

  void _showChatOptions(
    BuildContext context,
    String otherUserId,
    String otherName,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(
                  _t('view_profile'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 15),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  if (otherUserId.isNotEmpty) {
                    context.push('/profile/$otherUserId');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: _warmRose),
                title: Text(
                  _t('report_user'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: _warmRose,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _reportChatUser(otherUserId, otherName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: _warmRose),
                title: Text(
                  _t('block_user'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: _warmRose,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmBlockChatUser(otherUserId, otherName);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: _warmRose,
                ),
                title: Text(
                  _t('delete_conversation'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: _warmRose,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteChat(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reportChatUser(String otherUserId, String otherName) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null || otherUserId.isEmpty) return;

    var selectedReason = ReportReason.harassment;
    final detailsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(_t('report_user')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tf('report_user_body', {'name': otherName})),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReportReason>(
                  value: selectedReason,
                  decoration: InputDecoration(
                    labelText: _t('report_reason'),
                    border: const OutlineInputBorder(),
                  ),
                  items: ReportReason.values
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(_reportReasonLabel(reason)),
                        ),
                      )
                      .toList(),
                  onChanged: (reason) {
                    if (reason == null) return;
                    setDialogState(() => selectedReason = reason);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: _t('report_details_optional'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(_t('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(_t('submit_report')),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) {
      detailsController.dispose();
      return;
    }

    await ref
        .read(safetyServiceProvider)
        .reportUser(
          reporter: currentUser,
          reportedUserId: otherUserId,
          reportedUserName: otherName,
          reason: selectedReason,
          reasonLabel: _reportReasonLabel(selectedReason),
          source: 'chat',
          chatId: widget.chatId,
          details: detailsController.text,
        );
    detailsController.dispose();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_t('user_reported'))));
  }

  Future<void> _confirmBlockChatUser(
    String otherUserId,
    String otherName,
  ) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null || otherUserId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('block_user')),
        content: Text(_tf('block_user_body', {'name': otherName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _warmRose,
              foregroundColor: Colors.white,
            ),
            child: Text(_t('block_user')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(safetyServiceProvider)
        .blockUser(currentUserId: currentUser.id, blockedUserId: otherUserId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tf('user_blocked', {'name': otherName}))),
    );
    if (context.canPop()) {
      context.pop();
    }
  }

  String _tf(String key, Map<String, Object?> values) {
    return AppLocalizations.format(key, ref.read(localeProvider), values);
  }

  String _reportReasonLabel(ReportReason reason) {
    return switch (reason) {
      ReportReason.inappropriate => _t('report_reason_inappropriate'),
      ReportReason.spam => _t('report_reason_spam'),
      ReportReason.harassment => _t('report_reason_harassment'),
      ReportReason.fakeProfile => _t('report_reason_fake_profile'),
      ReportReason.scam => _t('report_reason_scam'),
      ReportReason.underage => _t('report_reason_underage'),
      ReportReason.other => _t('report_reason_other'),
    };
  }

  Future<void> _confirmDeleteChat(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _t('delete_conversation'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Text(_t('delete_conversation_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _warmRose),
            child: Text(
              _t('delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final service = ref.read(messageServiceProvider);
      await service.deleteChat(widget.chatId);
      if (!context.mounted) return;
      context.pop();
    }
  }
}

// ─── Voice Record Bottom Sheet ──────────────────────────────────────────────

class _VideoCallInvite {
  const _VideoCallInvite({this.roomId, this.callNotificationId});

  final String? roomId;
  final String? callNotificationId;
}

class _VoiceRecordSheet extends StatefulWidget {
  const _VoiceRecordSheet({required this.onSend, required this.onCancel});

  final Future<void> Function(String filePath, Duration duration) onSend;
  final VoidCallback onCancel;

  @override
  State<_VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends State<_VoiceRecordSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordingPath;
  Duration _duration = Duration.zero;
  Timer? _timer;
  bool _isSending = false;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Microphone permission required.',
                style: GoogleFonts.plusJakartaSans(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _duration = Duration.zero;
        _recordingPath = path;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final nextDuration = _duration + const Duration(seconds: 1);
        if (nextDuration >= _maxVoiceNoteDuration) {
          setState(() => _duration = _maxVoiceNoteDuration);
          _stopRecording();
          return;
        }
        setState(() => _duration = nextDuration);
      });
    } catch (e) {
      debugPrint('[VoiceRecord] Start error: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final path = await _recorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _hasRecording = path != null;
          _recordingPath = path ?? _recordingPath;
        });
      }
    } catch (e) {
      debugPrint('[VoiceRecord] Stop error: $e');
    }
  }

  Future<void> _sendRecording() async {
    if (_recordingPath == null || _isSending) return;
    setState(() => _isSending = true);
    final duration = _duration > _maxVoiceNoteDuration
        ? _maxVoiceNoteDuration
        : _duration;
    await widget.onSend(_recordingPath!, duration);
  }

  void _cancelRecording() async {
    _timer?.cancel();
    if (_isRecording) {
      await _recorder.stop();
    }
    if (_recordingPath != null) {
      try {
        await File(_recordingPath!).delete();
      } catch (_) {}
    }
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final mins = _duration.inMinutes;
    final secs = _duration.inSeconds % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Voice Message',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              timeStr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: _isRecording ? _warmRose : null,
              ),
            ),
            const SizedBox(height: 8),
            if (_isRecording)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _warmRose,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: 600.ms)
                      .fadeOut(duration: 600.ms),
                  const SizedBox(width: 8),
                  Text(
                    'Recording...',
                    style: GoogleFonts.plusJakartaSans(
                      color: _warmRose,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              '15 second max',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (_hasRecording && !_isRecording)
              Text(
                'Tap send to share',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel
                IconButton(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.close_rounded, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                // Record / Stop
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _isRecording ? _warmRose : _deepPlum,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? _warmRose : _deepPlum)
                              .withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                // Send
                IconButton(
                  onPressed: _hasRecording && !_isSending
                      ? _sendRecording
                      : null,
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _deepPlum,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size: 28,
                          color: _hasRecording ? _deepPlum : Colors.grey,
                        ),
                  style: IconButton.styleFrom(
                    backgroundColor: _hasRecording
                        ? _deepPlum.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
