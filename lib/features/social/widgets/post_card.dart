import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:nightingale_heart/core/widgets/pulse_avatar.dart';
import 'package:nightingale_heart/features/social/services/social_service.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

/// A card that renders a single community [PostModel].
///
/// Features:
/// - User avatar + name + timeago header with an overflow menu.
/// - Post text (expandable with "Read more" if longer than 3 lines).
/// - Optional image (tap to view full-screen).
/// - Action bar: Like (heart), Comment (chat bubble), Share.
/// - Comment preview with a "View all X comments" link.
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
    this.onImageTap,
    this.onShare,
    this.index = 0,
  });

  final PostModel post;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;
  final VoidCallback? onImageTap;
  final VoidCallback? onShare;
  final int index;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _commentsVisible = false;

  late final AnimationController _likeController;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _likeController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _handleLike() {
    _likeController.forward(from: 0);
    widget.onLike();
  }

  bool get _isLiked => widget.post.isLikedBy(widget.currentUserId);
  bool get _isOwnPost => widget.post.userId == widget.currentUserId;

  String _t(BuildContext context, String key) {
    return AppLocalizations.translate(key, Localizations.localeOf(context));
  }

  String _tf(BuildContext context, String key, Map<String, Object?> values) {
    return AppLocalizations.format(
      key,
      Localizations.localeOf(context),
      values,
    );
  }

  String _channelLabel(BuildContext context) {
    switch (widget.post.channelId) {
      case 'break_room':
      case 'night_shift_coffee':
      case 'wellness_checkin':
      case 'student_alumni':
      case 'travel_city_hub':
      case 'ceu_offers':
        return _t(context, 'community_channel_${widget.post.channelId}');
    }
    return widget.post.channelLabel;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;

    return GlassCard(
          padding: const EdgeInsets.all(0),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderRadius: AppTheme.borderRadiusMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header ----------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
                child: Row(
                  children: [
                    PulseAvatar(
                      imageUrl: post.userPhotoUrl,
                      name: post.userName,
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (post.createdAt != null)
                            Text(
                              timeago.format(post.createdAt!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') widget.onDelete();
                        if (value == 'report') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_t(context, 'post_reported')),
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        if (_isOwnPost)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, size: 18),
                                const SizedBox(width: 8),
                                Text(_t(context, 'delete')),
                              ],
                            ),
                          ),
                        if (!_isOwnPost)
                          PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                const Icon(Icons.flag_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(_t(context, 'report')),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ---- Content text ----------------------------------------------
              if (post.channelLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: _PostChannelPill(label: _channelLabel(context)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: _buildContentText(theme),
              ),

              // ---- Image (if present) ----------------------------------------
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: GestureDetector(
                    onTap: widget.onImageTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusSmall,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 220,
                          color: AppTheme.softLavender,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 220,
                          color: AppTheme.softLavender,
                          child: const Icon(Icons.broken_image_rounded),
                        ),
                      ),
                    ),
                  ),
                ),

              // ---- Divider ---------------------------------------------------
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Divider(height: 1),
              ),

              // ---- Action bar ------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                child: Row(
                  children: [
                    // Like
                    _ActionButton(
                      icon: AnimatedBuilder(
                        animation: _likeScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _likeScale.value,
                            child: Icon(
                              _isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: _isLiked ? AppTheme.warmRose : null,
                              size: 22,
                            ),
                          );
                        },
                      ),
                      label: post.likeCount > 0
                          ? '${post.likeCount}'
                          : _t(context, 'like'),
                      onTap: _handleLike,
                    ),

                    // Comment
                    _ActionButton(
                      icon: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      label: post.commentCount > 0
                          ? '${post.commentCount}'
                          : _t(context, 'comment'),
                      onTap: () {
                        setState(() => _commentsVisible = !_commentsVisible);
                        widget.onComment();
                      },
                    ),

                    // Share
                    _ActionButton(
                      icon: Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      label: _t(context, 'share'),
                      onTap: widget.onShare ?? () {},
                    ),
                  ],
                ),
              ),

              // ---- Comment preview -------------------------------------------
              if (_commentsVisible && post.comments.isNotEmpty)
                _CommentSection(comments: post.comments, postId: post.id),

              if (!_commentsVisible && post.comments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _commentsVisible = true),
                    child: Text(
                      _tf(context, 'view_all_comments', {
                        'count': post.commentCount,
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.deepPlum,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              if (post.comments.isEmpty) const SizedBox(height: 8),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (widget.index * 60).ms)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: 400.ms,
          delay: (widget.index * 60).ms,
        );
  }

  Widget _buildContentText(ThemeData theme) {
    final text = widget.post.content;
    const maxChars = 200;

    if (text.length <= maxChars || _expanded) {
      return Text(text, style: theme.textTheme.bodyLarge);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${text.substring(0, maxChars)}...',
          style: theme.textTheme.bodyLarge,
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = true),
          child: Text(
            _t(context, 'read_more'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.deepPlum,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PostChannelPill extends StatelessWidget {
  const _PostChannelPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.deepPlum.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.deepPlum,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentSection extends StatelessWidget {
  const _CommentSection({required this.comments, required this.postId});

  final List<Map<String, dynamic>> comments;
  final String postId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show last 2 comments at most in the preview.
    final visibleComments = comments.length > 2
        ? comments.sublist(comments.length - 2)
        : comments;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comments.length > 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                AppLocalizations.format(
                  'view_all_comments',
                  Localizations.localeOf(context),
                  {'count': comments.length},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.deepPlum,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ...visibleComments.map((c) {
            final name = c['userName'] as String? ?? '';
            final text = c['comment'] as String? ?? '';
            final photoUrl = c['userPhotoUrl'] as String?;
            final createdStr = c['createdAt'] as String?;
            DateTime? createdAt;
            if (createdStr != null) {
              createdAt = DateTime.tryParse(createdStr);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PulseAvatar(imageUrl: photoUrl, name: name, radius: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$name  ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: text,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (createdAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              timeago.format(createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
