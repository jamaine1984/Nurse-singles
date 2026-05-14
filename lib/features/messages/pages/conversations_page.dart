import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:nightingale_heart/core/models/message_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/features/messages/providers/message_providers.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

// ─── Color Constants ─────────────────────────────────────────────────────────
const Color _deepPlum = Color(0xFF0F766E);
const Color _warmRose = Color(0xFFDC2626);
const Color _cream = Color(0xFFFFFBEB);
const Color _softLavender = Color(0xFFF3E8FF);

/// Page that lists all conversations for the current user.
///
/// Each tile shows the other participant's avatar, name, last message preview,
/// timestamp, and an unread badge. Supports search, swipe-to-delete, pull to
/// refresh, loading shimmer, and an empty state.
class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String t(String key) => AppLocalizations.translate(key, locale);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0B15) : _cream,
      appBar: AppBar(
        title: Text(
          t('messages'),
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: currentUserAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            return Center(child: Text(t('please_sign_in_messages')));
          }
          return _buildBody(context, currentUser.id);
        },
        loading: () => _buildShimmerList(context),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String userId) {
    final chatsAsync = ref.watch(chatsProvider(userId));
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String t(String key) => AppLocalizations.translate(key, locale);

    return Column(
      children: [
        // ── Search Bar ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            decoration: InputDecoration(
              hintText: t('search_conversations'),
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey,
              ),
              prefixIcon: const Icon(Icons.search, color: _deepPlum),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1523) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: _deepPlum, width: 1.5),
              ),
            ),
          ),
        ),

        // ── Chat List ───────────────────────────────────────────────────
        Expanded(
          child: chatsAsync.when(
            data: (chats) {
              // Filter by search query (match on other participant name).
              final filtered = chats.where((chat) {
                if (_searchQuery.isEmpty) return true;
                final otherName = chat.otherUserName(userId);
                return otherName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
              }).toList();

              if (filtered.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 80),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final chat = filtered[index];
                  return _ConversationTile(
                        chat: chat,
                        currentUserId: userId,
                        onTap: () => context.push('/messages/${chat.id}'),
                        onDelete: () => _confirmDelete(context, chat.id),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                      .slideX(
                        begin: 0.05,
                        end: 0,
                        duration: 300.ms,
                        delay: (index * 50).ms,
                      );
                },
              );
            },
            loading: () => _buildShimmerList(context),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 80,
                  color: _deepPlum.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.translate(
                    'no_conversations_yet',
                    Localizations.localeOf(context),
                  ),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.translate(
                    'match_to_start_chatting',
                    Localizations.localeOf(context),
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  // ─── Shimmer Loading ────────────────────────────────────────────────────
  Widget _buildShimmerList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF2D2640)
        : const Color(0xFFE7E5E4);
    final highlightColor = isDark
        ? const Color(0xFF3D3554)
        : const Color(0xFFF5F5F4);

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Avatar shimmer
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: baseColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 10,
                    width: 40,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(
              duration: 1200.ms,
              color: highlightColor.withValues(alpha: 0.5),
            );
      },
    );
  }

  // ─── Delete Confirmation ────────────────────────────────────────────────
  Future<void> _confirmDelete(BuildContext context, String chatId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.translate(
            'delete_conversation',
            Localizations.localeOf(context),
          ),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Text(
          AppLocalizations.translate(
            'delete_conversation_warning',
            Localizations.localeOf(context),
          ),
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppLocalizations.translate(
                'cancel',
                Localizations.localeOf(context),
              ),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _warmRose),
            child: Text(
              AppLocalizations.translate(
                'delete',
                Localizations.localeOf(context),
              ),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final service = ref.read(messageServiceProvider);
      await service.deleteChat(chatId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'conversation_deleted',
              Localizations.localeOf(context),
            ),
          ),
        ),
      );
    }
  }
}

// ─── Conversation Tile ──────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
    required this.onDelete,
  });

  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final otherName = chat.otherUserName(currentUserId);
    final otherPhoto = chat.otherUserPhoto(currentUserId);
    final unread = chat.unreadFor(currentUserId);
    final hasUnread = unread > 0;

    // Format last message preview.
    String lastPreview = chat.lastMessage ?? '';
    if (lastPreview.isEmpty) {
      lastPreview = AppLocalizations.translate(
        'start_conversation',
        Localizations.localeOf(context),
      );
    }

    // Format time.
    String timeText = '';
    if (chat.lastMessageTime != null) {
      timeText = timeago.format(chat.lastMessageTime!, allowFromNow: true);
    }

    return Dismissible(
      key: ValueKey(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: _warmRose.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: _warmRose, size: 28),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion in the callback.
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ── Avatar ──────────────────────────────────────────────
              _buildAvatar(otherPhoto, otherName),
              const SizedBox(width: 14),

              // ── Name & Last Message ─────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: hasUnread
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: hasUnread
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontStyle: _isSpecialMessage(chat.lastMessage)
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: hasUnread
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Time & Unread Badge ─────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: hasUnread
                          ? _deepPlum
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (hasUnread) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _warmRose,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl, String name) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _softLavender,
          backgroundImage: photoUrl != null
              ? CachedNetworkImageProvider(photoUrl)
              : null,
          child: photoUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _deepPlum,
                  ),
                )
              : null,
        ),
        // Online indicator (positioned bottom-right).
        Positioned(
          bottom: 1,
          right: 1,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// Returns true if the last message preview indicates a non-text type.
  bool _isSpecialMessage(String? message) {
    if (message == null) return false;
    return message.startsWith('📷') ||
        message.startsWith('🎁') ||
        message.startsWith('📹') ||
        message.startsWith('🎤');
  }
}
